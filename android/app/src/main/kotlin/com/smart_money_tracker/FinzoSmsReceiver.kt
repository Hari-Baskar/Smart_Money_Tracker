package com.smart_money_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.provider.Telephony
import android.util.Log
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.smart_money_tracker.parser.SmsParser

class FinzoSmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages == null || messages.isEmpty()) return
            
            var fullBody = ""
            var sender = ""
            var timestamp = 0L

            for (message in messages) {
                if (message != null) {
                    sender = message.originatingAddress ?: sender
                    fullBody += message.messageBody ?: ""
                    timestamp = message.timestampMillis
                }
            }

            if (fullBody.isNotEmpty()) {
                val parsedTxn = SmsParser.parse(
                    smsBody = fullBody,
                    sender = sender,
                    date = java.util.Date(timestamp)
                )
                
                if (parsedTxn != null) {
                    Log.d("FINZO_SMS", "Saving potential financial SMS from $sender")
                    
                    val dbPath = context.getDatabasePath("pending_sms.db").absolutePath
                    val db = SQLiteDatabase.openOrCreateDatabase(dbPath, null)
                    
                    db.execSQL(
                        "CREATE TABLE IF NOT EXISTS pending_sms (id INTEGER PRIMARY KEY AUTOINCREMENT, sender TEXT, body TEXT, timestamp INTEGER)"
                    )
                    
                    val stmt = db.compileStatement("INSERT INTO pending_sms (sender, body, timestamp) VALUES (?, ?, ?)")
                    stmt.bindString(1, sender)
                    stmt.bindString(2, fullBody)
                    stmt.bindLong(3, timestamp)
                    stmt.executeInsert()
                    
                    db.close()
                    
                    // Insert temporary transaction for instant UI response
                    try {
                        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        val uid = prefs.getString("flutter.current_user_uid", null)
                        if (uid != null) {
                            val transDbPath = context.getDatabasePath("transactions_$uid.db").absolutePath
                            val transDb = SQLiteDatabase.openOrCreateDatabase(transDbPath, null)
                            
                            val isoDate = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").apply { 
                                timeZone = java.util.TimeZone.getTimeZone("UTC") 
                            }.format(java.util.Date(timestamp))

                            val insertStmt = transDb.compileStatement(
                                "INSERT OR REPLACE INTO transactions (id, amount, merchant, date, type, category, subcategory, rawSms, splits, isEdited, reference, bankId, paymentMethodId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                            )
                            
                            insertStmt.bindString(1, parsedTxn.id)
                            insertStmt.bindDouble(2, parsedTxn.amount)
                            insertStmt.bindString(3, parsedTxn.merchant)
                            insertStmt.bindString(4, isoDate + "Z") 
                            insertStmt.bindString(5, parsedTxn.type)
                            insertStmt.bindString(6, parsedTxn.category)
                            insertStmt.bindString(7, "General")
                            insertStmt.bindString(8, fullBody)
                            insertStmt.bindString(9, "[]")
                            insertStmt.bindLong(10, 0)
                            
                            if (parsedTxn.reference != null) insertStmt.bindString(11, parsedTxn.reference) else insertStmt.bindNull(11)
                            if (parsedTxn.bankId != null) insertStmt.bindString(12, parsedTxn.bankId) else insertStmt.bindNull(12)
                            if (parsedTxn.paymentMethodId != null) insertStmt.bindString(13, parsedTxn.paymentMethodId) else insertStmt.bindNull(13)
                            
                            insertStmt.executeInsert()
                            transDb.close()
                        }
                    } catch (e: Exception) {
                        Log.e("FINZO_SMS", "Error inserting temp transaction", e)
                    }
                    
                    // Show immediate native notification ONLY if app is not in foreground
                    if (!isAppInForeground(context)) {
                        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        val channelId = "transaction_channel_id"
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try {
                                notificationManager.deleteNotificationChannel("finzo_transaction_channel")
                            } catch (e: Exception) {}
                            val channel = NotificationChannel(
                                channelId,
                                "Transactions",
                                NotificationManager.IMPORTANCE_HIGH
                            )
                            notificationManager.createNotificationChannel(channel)
                        }

                        val title = if (parsedTxn.merchant != "-") {
                            "₹${parsedTxn.amount} at ${parsedTxn.merchant}"
                        } else {
                            "Transaction: ₹${parsedTxn.amount}"
                        }
                        
                        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                        val pendingIntent = android.app.PendingIntent.getActivity(
                            context,
                            0,
                            launchIntent,
                            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                        )

                        val notification = NotificationCompat.Builder(context, channelId)
                            .setSmallIcon(R.mipmap.launcher_icon)
                            .setContentTitle(title)
                            .setContentText("Tap to review in Finzo")
                            .setContentIntent(pendingIntent)
                            .setAutoCancel(true)
                            .setPriority(NotificationCompat.PRIORITY_HIGH)
                            .build()

                        notificationManager.notify(timestamp.toInt(), notification)
                    }
                } else {
                    // TESTING: Show 'Not a transaction' notification
                    Log.d("FINZO_SMS", "Received non-financial SMS from $sender")
                    val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val channelId = "transaction_channel_id"
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            notificationManager.deleteNotificationChannel("finzo_transaction_channel")
                        } catch (e: Exception) {}
                        val channel = NotificationChannel(
                            channelId,
                            "Transactions",
                            NotificationManager.IMPORTANCE_HIGH
                        )
                        notificationManager.createNotificationChannel(channel)
                    }
                    val notification = NotificationCompat.Builder(context, channelId)
                        .setSmallIcon(R.mipmap.launcher_icon)
                        .setContentTitle("Not a transaction")
                        .setContentText(fullBody)
                        .setAutoCancel(true)
                        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                        .build()
                    notificationManager.notify(timestamp.toInt() + 1, notification)
                }
            }

        } catch (e: Exception) {
            Log.e("FINZO_SMS", "Error in FinzoSmsReceiver", e)
        }
    }

    private fun isAppInForeground(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val packageName = context.packageName
        for (appProcess in appProcesses) {
            if (appProcess.importance == android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                appProcess.processName == packageName) {
                return true
            }
        }
        return false
    }
}
