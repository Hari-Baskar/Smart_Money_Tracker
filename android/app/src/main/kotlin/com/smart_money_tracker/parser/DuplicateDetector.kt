package com.smart_money_tracker.parser

import java.security.MessageDigest
import java.util.Date
import java.util.Calendar

object DuplicateDetector {
    fun generateStableId(
        rawBody: String,
        date: Date?,
        amount: Double,
        reference: String? = null,
        merchant: String = "UNKNOWN",
        type: String = "debit"
    ): String {
        if (!reference.isNullOrBlank()) {
            val cleanedRef = reference.trim().uppercase()
            if (cleanedRef.length >= 4) {
                return "txn_ref_$cleanedRef"
            }
        }

        val bodyClean = rawBody.trim().replace(Regex("\\s+"), " ").lowercase()
        val md = MessageDigest.getInstance("SHA-256")
        val bytes = bodyClean.toByteArray(Charsets.UTF_8)
        val digest = md.digest(bytes)
        val bodyHash = digest.joinToString("") { "%02x".format(it) }.substring(0, 16)

        if (date == null) {
            return "txn_hash_$bodyHash"
        }

        val cal = Calendar.getInstance().apply { time = date }
        val dateString = "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.MONTH) + 1}-${cal.get(Calendar.DAY_OF_MONTH)}"
        val cleanMerchant = merchant.trim().lowercase().replace(Regex("\\s+"), "")
        val fingerprintSource = "${amount.toInt()}|$cleanMerchant|${type.lowercase()}|$dateString"
        
        val fpBytes = fingerprintSource.toByteArray(Charsets.UTF_8)
        val fpDigest = md.digest(fpBytes)
        val fpHash = fpDigest.joinToString("") { "%02x".format(it) }.substring(0, 16)

        return "txn_fp_$fpHash"
    }
}
