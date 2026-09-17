package com.smart_money_tracker.parser
 
data class CategoryMapping(val category: String, val subcategory: String = "General")

object CategorizationSystem {
    private val merchantToCategory = mapOf(
        "zomato" to CategoryMapping("Food"),
        "swiggy" to CategoryMapping("Food"),
        "starbucks" to CategoryMapping("Food"),
        "mcdonalds" to CategoryMapping("Food"),
        "kfc" to CategoryMapping("Food"),
        "blinkit" to CategoryMapping("Food"),
        "zepto" to CategoryMapping("Food"),
        "bigbasket" to CategoryMapping("Food"),
        "uber" to CategoryMapping("Travel"),
        "ola" to CategoryMapping("Travel"),
        "petrol" to CategoryMapping("Travel"),
        "shell" to CategoryMapping("Travel"),
        "hpcl" to CategoryMapping("Travel"),
        "bpcl" to CategoryMapping("Travel"),
        "amazon" to CategoryMapping("Shopping"),
        "flipkart" to CategoryMapping("Shopping"),
        "netflix" to CategoryMapping("Entertainment"),
        "spotify" to CategoryMapping("Entertainment"),
        "hotstar" to CategoryMapping("Entertainment"),
        "airtel" to CategoryMapping("Bills"),
        "jio" to CategoryMapping("Bills"),
        "vi " to CategoryMapping("Bills"),
        "bescom" to CategoryMapping("Bills"),
        "atm" to CategoryMapping("Other")
    )

    fun getMapping(merchant: String, normalizedBody: String, type: String = "debit"): CategoryMapping {
        if (type == "credit") {
            if (normalizedBody.contains("salary")) return CategoryMapping("Salary", "General")
            return CategoryMapping("Other", "General")
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
            return CategoryMapping("Other", "General")
        }
        
        return CategoryMapping("Other", "General")
    }

    fun categorize(merchant: String, normalizedBody: String, type: String = "debit"): String {
        return getMapping(merchant, normalizedBody, type).category
    }

    fun categorizeSubcategory(merchant: String, normalizedBody: String, type: String = "debit"): String {
        return "General"
    }
}
