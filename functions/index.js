const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');
const { google } = require('googleapis');

admin.initializeApp();

// ── 환경변수 읽기 (firebase functions:config:set 으로 설정)
// firebase functions:config:set apple.shared_secret="xxx" google.service_account='{"type":"service_account",...}' app.api_key="xxx" app.package_name="com.mathbot.csat_tree"
const cfg = () => functions.config();

// ── API 키 인증 ──────────────────────────────────────────────────────────────
function checkApiKey(req, res) {
  const key = req.headers['x-api-key'];
  if (!key || key !== cfg().app?.api_key) {
    res.status(401).json({ valid: false, error: 'Unauthorized' });
    return false;
  }
  return true;
}

// ══════════════════════════════════════════════════════════════════════════════
// Apple IAP 영수증 검증
// POST https://.../verifyApple
// Headers: x-api-key
// Body: { receiptData: "base64...", productId: "mathbot_pro_monthly" }
// ══════════════════════════════════════════════════════════════════════════════
exports.verifyApple = functions
  .region('asia-northeast3')  // 서울 리전
  .https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (!checkApiKey(req, res)) return;

    const { receiptData, productId } = req.body;
    if (!receiptData) { res.status(400).json({ valid: false, error: 'receiptData required' }); return; }

    const payload = {
      'receipt-data': receiptData,
      password: cfg().apple?.shared_secret,
      'exclude-old-transactions': true,
    };

    try {
      let result = await callApple('https://buy.itunes.apple.com/verifyReceipt', payload);
      if (result.status === 21007) {
        // sandbox 영수증이 프로덕션으로 온 경우 → sandbox 재시도
        result = await callApple('https://sandbox.itunes.apple.com/verifyReceipt', payload);
      }

      if (result.status !== 0) {
        return res.json({ valid: false, error: `Apple status: ${result.status}` });
      }

      const latestReceipts = result.latest_receipt_info || [];
      const receipt = latestReceipts
        .filter(r => r.product_id === productId)
        .sort((a, b) => Number(b.expires_date_ms) - Number(a.expires_date_ms))[0];

      if (!receipt) return res.json({ valid: false, error: 'No receipt found' });

      const expiresMs = Number(receipt.expires_date_ms);
      return res.json({
        valid: expiresMs > Date.now(),
        productId: receipt.product_id,
        expiresAt: new Date(expiresMs).toISOString(),
        transactionId: receipt.transaction_id,
      });

    } catch (e) {
      functions.logger.error('Apple verify error', e);
      return res.status(500).json({ valid: false, error: 'Server error' });
    }
  });

async function callApple(url, payload) {
  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return resp.json();
}

// ══════════════════════════════════════════════════════════════════════════════
// Google Play 구매 검증
// POST https://.../verifyGoogle
// Headers: x-api-key
// Body: { purchaseToken: "...", productId: "mathbot_pro_monthly" }
// ══════════════════════════════════════════════════════════════════════════════
exports.verifyGoogle = functions
  .region('asia-northeast3')
  .https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (!checkApiKey(req, res)) return;

    const { purchaseToken, productId } = req.body;
    if (!purchaseToken || !productId) {
      return res.status(400).json({ valid: false, error: 'purchaseToken and productId required' });
    }

    try {
      const serviceAccount = JSON.parse(cfg().google?.service_account || '{}');
      const auth = new google.auth.GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
      });

      const androidpublisher = google.androidpublisher({ version: 'v3', auth });
      const packageName = cfg().app?.package_name || 'com.mathbot.csat_tree';

      const response = await androidpublisher.purchases.subscriptions.get({
        packageName,
        subscriptionId: productId,
        token: purchaseToken,
      });

      const sub = response.data;
      const expiresMs = Number(sub.expiryTimeMillis);
      const isActive = expiresMs > Date.now() && sub.paymentState !== 0;

      return res.json({
        valid: isActive,
        productId,
        expiresAt: new Date(expiresMs).toISOString(),
        autoRenewing: sub.autoRenewing,
      });

    } catch (e) {
      functions.logger.error('Google verify error', e);
      if (e.code === 404) return res.json({ valid: false, error: 'Purchase not found' });
      return res.status(500).json({ valid: false, error: 'Server error' });
    }
  });
