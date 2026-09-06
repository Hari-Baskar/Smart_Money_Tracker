package com.smart_money_tracker.parser

object TextNormalizer {
    fun normalize(rawSms: String): String {
        var text = rawSms.lowercase()
        
        // Normalize line breaks and tabs to spaces
        text = text.replace(Regex("[\\r\\n\\t]+"), " ")
        
        // Normalize multiple spaces
        text = text.replace(Regex("\\s{2,}"), " ")
        
        // Normalize currency symbols and words
        text = text.replace("₹", "rs ")
        text = text.replace("inr", "rs ")
        
        // Normalize quotes
        text = text.replace(Regex("[`´‘’]"), "'")
        text = text.replace(Regex("[“”]"), "\"")
        
        return text.trim()
    }
}
