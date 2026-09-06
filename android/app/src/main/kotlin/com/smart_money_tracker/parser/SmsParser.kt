package com.smart_money_tracker.parser

import java.util.Date

data class ParsedTransaction(
    val id: String,
    val amount: Double,
    val merchant: String,
    val date: Date?,
    val type: String, // "credit" or "debit"
    val category: String,
    val rawSms: String,
    val reference: String?,
    val bankId: String?,
    val paymentMethodId: String?
)

object SmsParser {
    fun parse(smsBody: String, sender: String, date: Date?): ParsedTransaction? {
        val normalizedBody = TextNormalizer.normalize(smsBody)

        if (!FinancialDetector.isFinancialSms(normalizedBody, sender)) {
            return null
        }

        val localAmount = RuleExtractionEngine.extractAmount(normalizedBody)
        var type = RuleExtractionEngine.extractType(normalizedBody)
        var reference = RuleExtractionEngine.extractReference(normalizedBody) ?: extractReferenceNumber(smsBody)
        val localMerchantRaw = RuleExtractionEngine.extractMerchant(normalizedBody, sender)

        val amount = localAmount
        var merchant = "-"
        var category = "Unknown"

        val isLocalSuccess = amount != null && amount > 0 && type != "unknown"

        if (isLocalSuccess) {
            var rawMerchant = (localMerchantRaw ?: "-").trim()
            val bareHonorific = Regex("^(MS|MR|DR|CR)$", RegexOption.IGNORE_CASE)

            if (rawMerchant == "OTHER" || 
                rawMerchant == "UNKNOWN" ||
                rawMerchant.uppercase().contains("YOUR BANK") || 
                rawMerchant == "-" ||
                rawMerchant.length < 2 ||
                bareHonorific.matches(rawMerchant)) {
                
                val extracted = extractMerchantFromBody(smsBody)
                if (extracted != null) {
                    merchant = extracted
                } else {
                    merchant = "-"
                }
            } else {
                merchant = rawMerchant
            }

            merchant = MerchantNormalizer.normalize(merchant, sender)
            category = CategorizationSystem.categorize(merchant, normalizedBody, type)
        } else {
            if (amount == null || amount <= 0) {
                return null
            }
            if (type == "unknown") {
                type = "debit"
            }
        }

        if (amount == null || amount <= 0) return null

        merchant = merchant.trim()
        val bareHonorific = Regex("^(MS|MR|DR|CR)$", RegexOption.IGNORE_CASE)
        if (merchant == "OTHER" || 
            merchant == "UNKNOWN" ||
            merchant.uppercase().contains("YOUR BANK") || 
            merchant == "-" ||
            merchant.length < 2 ||
            bareHonorific.matches(merchant)) {
            
            val extracted = extractMerchantFromBody(smsBody)
            if (extracted != null) {
                merchant = extracted
            } else {
                merchant = "-"
            }
        }
        
        merchant = MerchantNormalizer.normalize(merchant, sender)

        if (category == "Unknown" || category == "Other") {
           category = CategorizationSystem.categorize(merchant, normalizedBody, type)
        }

        if (category == "Unknown") {
            category = "Other"
        }

        if (reference != null) {
            reference = reference.trim().uppercase()
        }

        val stableId = DuplicateDetector.generateStableId(
            rawBody = smsBody,
            date = date,
            amount = amount,
            reference = reference,
            merchant = merchant,
            type = type
        )

        val autoBankId = PaymentDetector.detectBank(sender, normalizedBody)
        val autoPaymentMethodId = PaymentDetector.detectPaymentMethod(sender, normalizedBody)

        return ParsedTransaction(
            id = stableId,
            amount = amount,
            merchant = merchant,
            date = date,
            type = type,
            category = category,
            rawSms = smsBody,
            reference = reference,
            bankId = autoBankId,
            paymentMethodId = autoPaymentMethodId
        )
    }

    private fun extractReferenceNumber(body: String): String? {
        val explicitRegex = Regex("(?:ref(?:\\s+no|\\s+num)?\\.?\\s*:?|txn(?:\\s+id)?\\.?\\s*:?|upi(?:\\s+ref)?\\.?\\s*:?|reference(?:\\s+no)?\\.?\\s*:?)\\s*([a-z0-9]+)", RegexOption.IGNORE_CASE)
        val explicitMatch = explicitRegex.find(body)
        if (explicitMatch != null) {
            val ref = explicitMatch.groupValues.getOrNull(1)?.trim()
            if (ref != null && ref.length >= 6) return ref
        }

        val bankPatternRegex = Regex("(?:dr|cr|ref|txn)-([a-z0-9]+)", RegexOption.IGNORE_CASE)
        val bankMatch = bankPatternRegex.find(body)
        if (bankMatch != null) {
            val ref = bankMatch.groupValues.getOrNull(1)?.trim()
            if (ref != null && ref.length >= 6) return ref
        }

        val genericRegex = Regex("\\b([a-z]{4,5}[0-9]{6,15})\\b", RegexOption.IGNORE_CASE)
        val genericMatch = genericRegex.find(body)
        if (genericMatch != null) {
            return genericMatch.groupValues.getOrNull(1)?.trim()
        }

        val upi12Regex = Regex("\\b([0-9]{12})\\b")
        val upi12Match = upi12Regex.find(body)
        if (upi12Match != null) {
            return upi12Match.groupValues.getOrNull(1)?.trim()
        }

        return null
    }

    private fun extractMerchantFromBody(body: String): String? {
        fun extractPattern(pattern: String): String? {
            val match = Regex(pattern, RegexOption.IGNORE_CASE).find(body)
            if (match != null) {
                var name = match.groupValues.getOrNull(1)?.trim() ?: ""
                name = name.replace(Regex("_+"), " ").trim()

                val stopWords = listOf(" on ", " via ", " ref ", " txn ", " avail ", " available ")
                for (stop in stopWords) {
                    val idx = name.lowercase().indexOf(stop)
                    if (idx != -1) {
                        name = name.substring(0, idx).trim()
                    }
                }
                
                if (name.isNotEmpty() && !isGenericWord(name)) return name
            }
            return null
        }

        var result = extractPattern("payee\\s+([A-Za-z0-9\\s._\\-&]{2,40}?)(?:\\s+for(?:\\s+rs\\.?|\\s+inr|\\s+\\d)|\\s+on|\\s+ref|$)")
        result = result ?: extractPattern("received\\s+from\\s+([A-Za-z0-9\\s._\\-&]{2,40}?)(?:\\s+towards|\\s+on|\\s+ref|$)")
        result = result ?: extractPattern("credited\\s+(?:by|from)\\s+([A-Za-z0-9\\s._\\-&]{2,40}?)(?:\\s+on|\\s+ref|$)")
        result = result ?: extractPattern("remitter\\s*[:-]?\\s*([A-Za-z0-9\\s._\\-&]{2,40}?)(?:\\s+on|\\s+ref|$)")
        result = result ?: extractPattern("refund\\s+from\\s+([A-Za-z0-9\\s._\\-&]{2,40}?)(?:\\s+on|\\s+ref|$)")
        result = result ?: extractPattern("debited(?:.*?)?to\\s+([A-Za-z0-9\\s._\\-&]{2,40}?)(?:\\s+info|\\s+on|\\s+ref|$)")
        result = result ?: extractPattern("favouring\\s+([^,.\\n]{3,30})")
        result = result ?: extractPattern("paid to\\s+([A-Za-z0-9\\s&]{3,30})")

        return result
    }

    private fun isGenericWord(word: String): Boolean {
        val lower = word.lowercase()
        if (lower.startsWith("rs") || lower.startsWith("inr") || Regex("^[\\d\\.,\\s]+$").matches(word)) return true

        if (lower.contains("xxx") || 
            lower.contains("***") ||
            Regex("(?:x|\\*){2,}\\d+").containsMatchIn(lower) || 
            Regex("\\d+(?:x|\\*){2,}").containsMatchIn(lower) ||
            Regex("\\.{2,}\\d+").containsMatchIn(lower)) {
            return true
        }

        if (lower.contains("your bank") || 
            lower.contains("account") || 
            lower.contains("card") || 
            lower.contains("immediately") || 
            lower.contains("balance") ||
            lower.length < 3) {
            return true
        }
        return false
    }
}
