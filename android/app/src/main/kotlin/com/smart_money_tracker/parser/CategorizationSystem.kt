package com.smart_money_tracker.parser

object CategorizationSystem {
    private val merchantToCategory = mapOf(
        "zomato" to "Food",
        "swiggy" to "Food",
        "uber" to "Travel",
        "ola" to "Travel",
        "amazon" to "Shopping",
        "flipkart" to "Shopping",
        "blinkit" to "Groceries",
        "zepto" to "Groceries",
        "bigbasket" to "Groceries",
        "netflix" to "Entertainment",
        "spotify" to "Entertainment",
        "hotstar" to "Entertainment",
        "airtel" to "Bills",
        "jio" to "Bills",
        "vi " to "Bills",
        "bescom" to "Bills",
        "petrol" to "Fuel",
        "shell" to "Fuel",
        "hpcl" to "Fuel",
        "bpcl" to "Fuel",
        "atm" to "Cash Withdrawal",
        "starbucks" to "Food",
        "mcdonalds" to "Food",
        "kfc" to "Food"
    )

    fun categorize(merchant: String, normalizedBody: String, type: String = "debit"): String {
        if (type == "credit") {
            if (normalizedBody.contains("salary")) return "Salary"
            if (normalizedBody.contains("refund")) return "Refunds"
            return "Other"
        }

        val merchantLower = merchant.lowercase()
        
        for ((keyStr, value) in merchantToCategory) {
            val key = keyStr.trim()
            val regex = Regex("\\b$key\\b")
            if (regex.containsMatchIn(merchantLower) || regex.containsMatchIn(normalizedBody)) {
                return value
            }
        }

        if (Regex("\\batm\\b").containsMatchIn(normalizedBody) || Regex("\\bcash\\b").containsMatchIn(normalizedBody)) {
            return "Cash Withdrawal"
        }
        
        return "Unknown"
    }
}
