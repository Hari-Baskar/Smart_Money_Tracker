const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { defineSecret } = require('firebase-functions/params');
const geminiApiKey = defineSecret('GEMINI_API_KEY');

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

exports.parseSmsWithGemini = functions.runWith({ secrets: [geminiApiKey] }).https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const smsBody = data.smsBody;
  if (!smsBody) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with an "smsBody".'
    );
  }

  try {
    const genAI = new GoogleGenerativeAI(geminiApiKey.value());
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `You are a highly advanced financial analyzer for bank SMS messages.
Your task is to determine if an SMS or notification is a valid personal transaction (DEBIT for expense, or CREDIT for income).

SMS/Notification Content: ${smsBody}

Return ONLY a STRICT JSON object:
{
"type": "debit" | "credit" | "junk",
"amount": number,
"merchant": "string",
"category": "Food" | "Travel" | "Shopping" | "Bills" | "Entertainment" | "Health" | "Investment" | "Salary" | "Other",
"date": "YYYY-MM-DD" | null,
"reference": "string" | null
}
}
IMPORTANT RULES:
1. "category" MUST be exactly one of the options listed above. Do not make up your own category (e.g. no "transfer"). If unsure, use "Other".
2. "merchant" is the person, business, or entity that sent or received the money (e.g., "Amazon", "CHINNAMMAL", "Paytm"). NEVER use the amount (e.g. "RS.3000.00"), date, or generic words. If the merchant is NOT explicitly clear, or if it is just a location/branch name (e.g. "MARUNGAPURI"), output "-".`;

    const result = await model.generateContent(prompt);
    let cleanText = result.response.text().trim();

    // Clean up markdown block if present
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.substring(7);
    } else if (cleanText.startsWith('```')) {
      cleanText = cleanText.substring(3);
    }
    if (cleanText.endsWith('```')) {
      cleanText = cleanText.substring(0, cleanText.length - 3);
    }

    const parsedData = JSON.parse(cleanText.trim());
    return parsedData;

  } catch (error) {
    console.error("Gemini Error:", error);
    throw new functions.https.HttpsError('internal', 'Failed to parse SMS with AI.');
  }
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
