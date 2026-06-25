const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');
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
