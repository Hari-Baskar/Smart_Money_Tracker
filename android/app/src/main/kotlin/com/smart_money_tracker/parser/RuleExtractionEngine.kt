package com.smart_money_tracker.parser

object RuleExtractionEngine {
    fun extractAmount(text: String): Double? {
        val lowerText = text.lowercase()
        val patterns = listOf(
            Regex("(?:rs\\.?|inr|amt|spent)\\s*:?\\s*([\\d,]+(?:\\.\\d{1,2})?)"),
            Regex("debited\\s*(?:by|for)?\\s*(?:rs\\.?)?\\s*:?\\s*([\\d,]+(?:\\.\\d{1,2})?)"),
            Regex("credited\\s*(?:with|by|for)?\\s*(?:rs\\.?)?\\s*:?\\s*([\\d,]+(?:\\.\\d{1,2})?)"),
            Regex("(?:rs\\.?)\\s*:?\\s*([\\d,]+(?:\\.\\d{1,2})?)\\s*(?:debited|credited)")
        )

        for (pattern in patterns) {
            val matches = pattern.findAll(lowerText)
            for (match in matches) {
                val prefix = lowerText.substring(0, match.range.first)
                val lookback = if (prefix.length > 30) prefix.substring(prefix.length - 30) else prefix
                
                if (Regex("\\b(bal|balance)\\b|acbal|clrbal|avl\\s*bal|avail\\s*bal").containsMatchIn(lookback)) {
                    continue
                }
                val amtStr = match.groupValues[1].replace(",", "")
                val valDouble = amtStr.toDoubleOrNull()
                if (valDouble != null && valDouble > 0) {
                    return valDouble
                }
            }
        }
        return null
    }

    fun extractMerchant(text: String, sender: String): String? {
        val lower = text.lowercase()
        if (lower.contains("atm withdrawal") || 
            lower.contains("cash withdrawal") || 
            lower.contains("[atm") || 
            lower.contains(" nfs ")) {
            return "-"
        }

        val patterns = listOf(
            Regex("""received\s+from\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+towards|\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE),
            Regex("""credited\s+(?:by|from)\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE),
            Regex("""(?:received|credited|refunded)(?:.*?)?\bfrom\s+([a-z0-9\s*\._\-&'"]+?)(?:-[a-z0-9@!¡\-]+)?(?:\s+on|\s+ref|¡|\(|\[|$)""", RegexOption.IGNORE_CASE),
            Regex("""remitter\s*[:-]?\s*([a-z0-9\s*\._\-&'"]+?)(?:\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE),
            Regex("""refund\s+from\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE),
            Regex("""debited(?:.*?)?to\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+info|\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE),
            Regex("""favouring\s+([^,.\n]+)""", RegexOption.IGNORE_CASE),
            Regex("""vpa\s+([a-z0-9@\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE),
            Regex("""paid\s+to\s+([a-z0-9\s*\.&'"-]+)(?:\.|\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE),
            Regex("""payee\s+([a-z0-9\s*\._\-&'"]+?)(?:\s+for(?:\s+rs\.?|\s+inr|\s+\d)|\s+on|\s+ref|$)""", RegexOption.IGNORE_CASE)
        )

        for (pattern in patterns) {
            val match = pattern.find(text)
            if (match != null) {
                var found = match.groupValues[1].trim()
                if (found.endsWith(" on", ignoreCase = true)) found = found.substring(0, found.length - 3)
                if (found.endsWith(" for rs", ignoreCase = true)) found = found.substring(0, found.length - 7)
                
                val lowerFound = found.lowercase()
                val isAmount = lowerFound.startsWith("rs") || 
                               lowerFound.startsWith("inr") || 
                               Regex("^[\\d\\.,]+$").matches(found)
                               
                val isMaskedAccount = lowerFound.contains("xxx") || 
                                      lowerFound.contains("***") ||
                                      Regex("(?:x|\\*){2,}\\d+").containsMatchIn(lowerFound) || 
                                      Regex("\\d+(?:x|\\*){2,}").containsMatchIn(lowerFound) ||
                                      Regex("\\.{2,}\\d+").containsMatchIn(lowerFound)
                               
                if (isAmount || isMaskedAccount) {
                    continue
                }

                if (found.length > 2) {
                    return found
                }
            }
        }
        return null
    }

    fun extractType(text: String): String {
        var lower = text.lowercase()
        
        val remarkKeywords = listOf("payer remark", "upi remark", "remarks -", "remark -", "remarks:")
        for (keyword in remarkKeywords) {
            if (lower.contains(keyword)) {
                lower = lower.split(keyword)[0]
            }
        }

        var hasClearCredit = false
        val creditSignals = listOf("received", "refund", "cashback", "deposited", "deposit", "cr", "inward")
        if (creditSignals.any { Regex("\\b$it\\b").containsMatchIn(lower) }) {
            hasClearCredit = true
        }
        if (Regex("\\bcredited\\b").containsMatchIn(lower) && 
            !lower.contains("credited to payee") && 
            !lower.contains("credited to merchant") &&
            !lower.contains("credited to account of") &&
            !lower.contains("credited to a/c of")) {
            hasClearCredit = true
        }
        if (lower.contains("added to wallet") || lower.contains("salary credited")) {
            hasClearCredit = true
        }

        var hasClearDebit = false
        val debitSignals = listOf("spent", "paid", "withdrawn", "sent to", "debited", "payee", "dr", "withdrawal", "pos", "purchase", "ecom", "outward")
        if (debitSignals.any { Regex("\\b$it\\b").containsMatchIn(lower) }) {
            hasClearDebit = true
        }

        if (hasClearCredit && !hasClearDebit) {
            return "credit"
        } else if (hasClearDebit && !hasClearCredit) {
            return "debit"
        } else if (hasClearCredit && hasClearDebit) {
            val hasStrongCredit = lower.contains("is credited") || 
                                  lower.contains("account credited") || 
                                  lower.contains("a/c credited") || 
                                  lower.contains("credited by") ||
                                  lower.contains("credited with") ||
                                  lower.contains("deposited in")
            if (hasStrongCredit) return "credit"
            return "debit"
        }
        return "unknown"
    }

    fun extractReference(text: String): String? {
        val patterns = listOf(
            Regex("\\[([a-z0-9\\-\\s]*\\d[a-z0-9\\-\\s]*)\\]", RegexOption.IGNORE_CASE),
            Regex("ref\\s*(?:no\\.?|num\\.?|id)?\\s*:?\\s*([a-z0-9]+)", RegexOption.IGNORE_CASE),
            Regex("utr\\s*(?:no\\.?|num\\.?)?\\s*:?\\s*([a-z0-9]+)", RegexOption.IGNORE_CASE),
            Regex("txn\\s*(?:id|no\\.?)?\\s*:?\\s*([a-z0-9]+)", RegexOption.IGNORE_CASE)
        )

        for (pattern in patterns) {
            val match = pattern.find(text)
            if (match != null) {
                return match.groupValues[1].trim()
            }
        }
        return null
    }
}
