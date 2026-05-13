class TextNormalizer {
  static String normalize(String rawSms) {
    String text = rawSms.toLowerCase();
    
    // Normalize line breaks and tabs to spaces
    text = text.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    
    // Normalize multiple spaces
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ');
    
    // Normalize currency symbols and words
    text = text.replaceAll('₹', 'rs ');
    text = text.replaceAll('inr', 'rs ');
    
    // Normalize quotes
    text = text.replaceAll(RegExp(r'[`´‘’]'), "'");
    text = text.replaceAll(RegExp(r'[“”]'), '"');
    
    return text.trim();
  }
}
