package com.smart_money_tracker.parser
 
data class CategoryMapping(val category: String, val subcategory: String = "General")

object CategorizationSystem {
    private val merchantToCategory = mapOf(
        "zomato" to CategoryMapping("Food", "Delivery"),
        "swiggy" to CategoryMapping("Food", "Delivery"),
        "starbucks" to CategoryMapping("Food", "Restaurant"),
        "mcdonalds" to CategoryMapping("Food", "Restaurant"),
        "kfc" to CategoryMapping("Food", "Restaurant"),
        "blinkit" to CategoryMapping("Food", "Groceries"),
        "zepto" to CategoryMapping("Food", "Groceries"),
        "bigbasket" to CategoryMapping("Food", "Groceries"),
        "uber" to CategoryMapping("Travel", "Taxi/Uber"),
        "ola" to CategoryMapping("Travel", "Taxi/Uber"),
        "petrol" to CategoryMapping("Travel", "Fuel"),
        "shell" to CategoryMapping("Travel", "Fuel"),
        "hpcl" to CategoryMapping("Travel", "Fuel"),
        "bpcl" to CategoryMapping("Travel", "Fuel"),
        "amazon" to CategoryMapping("Shopping", "General"),
        "flipkart" to CategoryMapping("Shopping", "General"),
        "netflix" to CategoryMapping("Entertainment", "Streaming"),
        "spotify" to CategoryMapping("Entertainment", "Streaming"),
        "hotstar" to CategoryMapping("Entertainment", "Streaming"),
        "airtel" to CategoryMapping("Bills", "Mobile"),
        "jio" to CategoryMapping("Bills", "Mobile"),
        "vi " to CategoryMapping("Bills", "Mobile"),
        "bescom" to CategoryMapping("Bills", "Electricity"),
        "atm" to CategoryMapping("Other", "General")
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
        return getMapping(merchant, normalizedBody, type).subcategory
    }
}
