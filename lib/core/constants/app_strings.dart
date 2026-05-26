class AppStrings {
  static const String appName = "Expense Tracker";
  static const String geminiApiKey = 'AIzaSyButrVBSxyPD2XKJBQBximwUoIsw_7htLo';
  static const String openaiApiKey =
      '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';

  static const String aboutContent = '''
Smart Money Tracker v1.0.0

Smart Money Tracker is your ultimate financial companion, designed to help you monitor expenses, manage budgets, and achieve your financial goals with ease. 

Our app provides a secure and intuitive interface to track your daily transactions, offering powerful insights and automated categorization to give you full control over your personal finances.

Built with a commitment to simplicity and security, we strive to make financial management accessible to everyone.
''';

  static const String privacyPolicyContent = '''
Privacy Policy

Effective Date: May 26, 2026

Your privacy is critically important to us. Smart Money Tracker is designed to provide you with powerful financial insights and secure automated transaction tracking. This Privacy Policy details how we collect, handle, store, and process your data to help you manage your personal finances with confidence.

1. Data Collection & Usage:

We collect necessary information such as your name, email address (via Google Sign-In), and transaction details that you manually input or that are automatically parsed (upon your explicit consent) to provide our core financial tracking services.

2. SMS Permission & Transaction Data Usage:

Smart Money Tracker requires access to your device's SMS messages to power our automatic expense and income tracking features.

- Scope of Access: The app reads and scans only official transactional SMS messages sent by banks, UPI providers, credit/debit card issuers, and other financial institutions.
- OTP Protection: One-Time Passwords (OTPs), authentication codes, and critical security credentials are strictly excluded. They are never collected, stored, or processed.
- No Personal Chat Scans: Personal conversations, private texts, contact names, and non-financial SMS messages are completely ignored and never accessed.
- AI-Powered Analysis: To improve transaction categorization and generate actionable financial insights, some transaction-related SMS data may be securely processed using AI services (such as Google AI services).
- Core App Functionality: SMS access is used strictly for the core app functionality of automatic expense tracking and income detection.
- Revocability: You can grant or revoke SMS permissions at any time directly through your device's operating system settings. If revoked, the app will continue to function normally without automatic tracking.

3. Permissions Used:

To support automatic expense tracking, the app utilizes the following system permissions:
- READ_SMS: Allows the app to read existing transactional SMS messages from your inbox to run initial expense scans and construct your dashboard.
- RECEIVE_SMS: Allows the app to listen for incoming financial SMS alerts in real-time, enabling immediate detection of new transactions.

4. Data Security:

We enforce robust physical and technical safeguards to keep your personal and financial information safe:
- Secure Transmission: All transactional data sent to our backend services (such as Firebase and AI services) is encrypted in transit and handled securely.
- No Data Selling: We have a strict policy against renting, sharing, or selling your financial data or personal information to third parties or marketing companies.
- Minimal Data Usage: We practice data minimization, processing only what is necessary to categorize your expenses and provide you with financial insights.
- Privacy Protection: We constantly audit our data practices to align with industry standard security regulations and protect your digital privacy.

5. Data Storage & User Control:

Your data is securely stored using Google's Firebase infrastructure. You retain full ownership and control over your personal data. You can delete your account and all associated transaction data permanently at any time directly from the app's settings screen.


By using Smart Money Tracker and enabling automated SMS sync, you consent to our data practices as described in this policy.
''';

  static const String termsAndConditionsContent = '''
Terms and Conditions

By using Smart Money Tracker, you agree to the following terms:

1. Use of Service:

The app is provided to help you track personal finances. You are responsible for the accuracy of the data you input.

2. No Financial Advice:

The insights and summaries provided by the app are for informational purposes only and do not constitute professional financial advice.

3. Third-Party Services:

We utilize third-party services such as Firebase for database hosting and Google for authentication. Their respective terms of service apply to their use.

4. "As Is" Basis:

The app is provided "as is" without warranties of any kind. We are not liable for any financial losses or errors resulting from the use of the app.

5. Account Termination:

We reserve the right to suspend or terminate accounts that violate these terms or engage in fraudulent activities.
''';
}
