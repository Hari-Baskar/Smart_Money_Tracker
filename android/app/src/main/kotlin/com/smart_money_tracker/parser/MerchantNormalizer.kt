package com.smart_money_tracker.parser

object MerchantNormalizer {
    fun normalize(rawMerchant: String?, sender: String): String {
        if (rawMerchant.isNullOrEmpty() || rawMerchant == "OTHER" || rawMerchant == "UNKNOWN" || rawMerchant.length <= 2) {
            return "-"
        }

        var clean = rawMerchant.uppercase().trim()
        
        // Remove quotes and common symbols that act as separators
        clean = clean.replace(Regex("['\"`´‘’“”\\*_\\-]+"), " ")
        
        // Clean up multiple spaces resulting from symbol replacement
        clean = clean.replace(Regex("\\s+"), " ").trim()
        
        // Strip honorific prefixes only when followed by a single word (person name)
        val honorificPattern = Regex("^(DR|CR|MR|MS)\\s+(\\S+)$")
        val honorificMatch = honorificPattern.find(clean)
        if (honorificMatch != null) {
            clean = honorificMatch.groupValues[2]
        }

        if (clean.startsWith("PAYEE ")) {
            clean = clean.substring(6).trim()
        } else if (clean.startsWith("MERCHANT ")) {
            clean = clean.substring(9).trim()
        }

        if (clean.contains("AMAZON")) return "AMAZON"
        if (clean.contains("SWIGGY")) return "SWIGGY"
        if (clean.contains("ZOMATO")) return "ZOMATO"
        if (clean.contains("UBER")) return "UBER"
        if (clean.contains("OLA")) return "OLA"
        if (clean.contains("FLIPKART")) return "FLIPKART"
        if (clean.contains("ZEPTO")) return "ZEPTO"
        if (clean.contains("BLINKIT")) return "BLINKIT"

        return clean
    }
}
