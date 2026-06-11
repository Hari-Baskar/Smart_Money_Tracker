const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');
const { GoogleGenerativeAI } = require('@google/generative-ai');

admin.initializeApp();

/*
// DISABLED: Migrated to local device notifications to reduce server costs and Firestore reads to $0
exports.dailyTransactionCheck = functions.pubsub.schedule('every day 20:00').timeZone('Asia/Kolkata').onRun(async (context) => {
  const usersSnapshot = await admin.firestore().collection('users').get();

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) continue; // Cannot send notification without token

    const transactionsSnapshot = await admin.firestore()
      .collection('users')
      .doc(userDoc.id)
      .collection('transactions')
      .where('date', '>=', today.toISOString())
      .where('date', '<=', endOfDay.toISOString())
      .get();

    if (transactionsSnapshot.empty) {
      // Send: add today transactions
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'No Transactions Today',
          body: 'Did you spend anything today? Do not forget to add your transactions!',
        },
      }).catch(err => console.error(err));
    } else {
      let hasUnknown = false;
      transactionsSnapshot.forEach(doc => {
        if (doc.data().category === 'Unknown') {
          hasUnknown = true;
        }
      });

      if (hasUnknown) {
        // Send: unknown transactions
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: 'Uncategorized Transactions',
            body: 'You have some unknown transactions today. Please categorize them!',
          },
        }).catch(err => console.error(err));
      }
    }
  }

  return null;
});
*/

exports.parseSmsWithGemini = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated (highly secure!)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const smsBody = data.smsBody;
  if (!smsBody) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with an "smsBody" parameter.'
    );
  }

  const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key || 'AIzaSyButrVBSxyPD2XKJBQBximwUoIsw_7htLo';
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Gemini API key is not configured.'
    );
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const prompt = `You are a highly advanced financial analyzer for bank SMS messages.
Your task is to determine if an SMS or notification is a valid personal transaction (DEBIT for expense, or CREDIT for income).
EXPENSES (debit) include: payments to merchants, UPI transfers to people, ATM withdrawals, bill payments, and card swipes.
INCOME (credit) include: salary, received money, cashback, bank interest, refunds, and money added to wallet.

CRITICAL RULES:
1. Set "type": "debit" if money was spent or sent. Keywords: "paid", "sent", "debited", "towards", "transferred", "vpa", "to payee".
2. Set "type": "credit" if money was received or added. Keywords: "credited", "received", "added", "deposited", "refunded", "cashback".
3. If the message is an OTP, a login alert, a balance check, a payment REQUEST (not yet paid, including pending cheque clearing notifications and Positive Pay alerts which are not finalized deductions yet), a failed/declined transaction, a purely informational telecom recharge confirmation (e.g. "recharge successful", "pack activated"), or a promotional/marketing offer/ad (e.g. "up to ₹XXX", "win cashback", "earn rewards", "earn laddoos"), set "type": "junk".
4. For "merchant", extract the FULL name of the store, business, or person.
   - Look for patterns like "debited for payee [NAME]", "Paid to [NAME]", "Received from [NAME]", "Credited by [NAME]".
   - Bank SMS messages often format payee names with underscores, e.g. "MS_VIKRAANTH_AGENCYY_". Replace ALL underscores with spaces: return "MS VIKRAANTH AGENCYY" NOT "MS".
   - Prefixes like MS, MR, DR that appear BEFORE a business/person name are PART OF the name. NEVER return just the prefix alone. Always include the full name after the prefix.
   - Good: "Zomato", "Swiggy", "Amazon", "Salary", "Cashback", "MS VIKRAANTH AGENCYY", "MR RAJAN STORES".
   - Bad: "YOUR BANK", "IOB", "HDFC", "TXN ID", "BANK IMMEDIATELY", "VPA", "SB-xxx", "MS", "MR", "DR" (prefix alone).
5. If you cannot find a clear merchant name, set "merchant": "Bank Transaction".
6. Categorize the transaction into: Food, Travel, Shopping, Bills, Groceries, Entertainment, Health, Investment, Income, Salary, Cashback, Other.

SMS/Notification Content: ${smsBody}

Return ONLY a STRICT JSON object:
{
"type": "debit" | "credit" | "junk",
"amount": number,
"merchant": "string",
"category": "string",
"date": "YYYY-MM-DD" | null,
"reference": "string" | null
}`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    if (text) {
      let cleanContent = text.trim();
      
      // Handle potential markdown formatting
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.replace('```json', '');
      }
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.replace(/```$/, '');
      }
      cleanContent = cleanContent.trim();
      
      const parsed = JSON.parse(cleanContent);
      return parsed;
    }
  } catch (error) {
    console.error('Error generating content from Gemini API:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to parse SMS using Gemini API: ' + error.message
    );
  }

  return null;
});

exports.cleanupUserData = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  console.log(`User ${uid} deleted from Auth. Starting background data cleanup.`);
  
  const userDoc = admin.firestore().collection('users').doc(uid);
  
  try {
    // This instantly deletes the document and all subcollections recursively on the server
    await admin.firestore().recursiveDelete(userDoc);
    console.log(`Successfully wiped all database records for user ${uid}.`);
  } catch (error) {
    console.error(`Failed to wipe data for user ${uid}:`, error);
  }
});
