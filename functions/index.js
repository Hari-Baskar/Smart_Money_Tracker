const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();

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
