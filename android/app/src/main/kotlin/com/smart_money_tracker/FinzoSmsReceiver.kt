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
                val lowerBody = fullBody.lowercase()
                // Fast filter: only save if it has financial keywords
                val isFinancial = Regex("(?<![a-z])(?:rs|inr|amt)(?![a-z])|₹|debited|credited|spent|paid|received").containsMatchIn(lowerBody)
                
                if (isFinancial) {
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
                    
                    // Show immediate native notification ONLY if app is not in foreground
                    if (!isAppInForeground(context)) {
                        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        val channelId = "finzo_transaction_channel"
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val channel = NotificationChannel(
                                channelId,
                                "Transactions",
                                NotificationManager.IMPORTANCE_HIGH
                            )
                            notificationManager.createNotificationChannel(channel)
                        }

                        val amountRegex = Regex("(?i)(?:rs\\.?|inr|₹)\\s*([\\d,]+\\.?\\d*)")
                        val match = amountRegex.find(fullBody)
                        val amountStr = match?.groupValues?.getOrNull(1) ?: ""
                        
                        val title = if (amountStr.isNotEmpty()) "Transaction: ₹$amountStr" else "New Transaction Detected"
                        
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
