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
                
                // Strict check: Ignore normal 10-digit phone numbers (must be a commercial header like AD-HDFCBK)
                val isCommercialSender = !Regex("^\\+?[0-9]{10,}\$").matches(sender)
                
                if (isFinancial && isCommercialSender) {
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
                            
                            val tempId = "temp_native_$timestamp"
                            val type = if (Regex("(?i)(debited|spent|paid|withdrawn)").containsMatchIn(fullBody)) "debit" else "credit"
                            val isoDate = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").apply { 
                                timeZone = java.util.TimeZone.getTimeZone("UTC") 
                            }.format(java.util.Date(timestamp))

                            val insertStmt = transDb.compileStatement(
                                "INSERT OR REPLACE INTO transactions (id, amount, merchant, date, type, category, subcategory, rawSms, splits, isEdited, reference, bankId, paymentMethodId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                            )
                            val amountRegexNative = Regex("(?i)(?:rs\\.?|inr|₹)\\s*([\\d,]+\\.?\\d*)")
                            val matchNative = amountRegexNative.find(fullBody)
                            val amountStrNative = matchNative?.groupValues?.getOrNull(1) ?: ""
                            
                            insertStmt.bindString(1, tempId)
                            insertStmt.bindDouble(2, amountStrNative.replace(",", "").toDoubleOrNull() ?: 0.0)
                            insertStmt.bindString(3, "-")
                            insertStmt.bindString(4, isoDate + "Z") 
                            insertStmt.bindString(5, type)
                            insertStmt.bindString(6, "Other")
                            insertStmt.bindString(7, "General")
                            insertStmt.bindString(8, fullBody)
                            insertStmt.bindString(9, "[]")
                            insertStmt.bindLong(10, 0)
                            insertStmt.bindNull(11) // reference
                            insertStmt.bindNull(12) // bankId
                            insertStmt.bindNull(13) // paymentMethodId
                            
                            insertStmt.executeInsert()
                            transDb.close()
                        }
                    } catch (e: Exception) {
                        Log.e("FINZO_SMS", "Error inserting temp transaction", e)
                    }
                    
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
                } else {
                    // TESTING: Show 'Not a transaction' notification
                    Log.d("FINZO_SMS", "Received non-financial SMS from $sender")
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
