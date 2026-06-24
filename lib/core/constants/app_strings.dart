class AppStrings {
  static const String baseAppName = "Finzo";
  static const String appName = "₹ $baseAppName";
  static const String appIconPath = "assets/images/app_icon2.png";

  // AdMob Ad Unit IDs
  static const String androidBannerAdUnitId =
      'ca-app-pub-1293091196510342/6897602915';
  static const String androidNativeAdUnitId =
      'ca-app-pub-1293091196510342/1879715575';
  static const String androidRewardedAdUnitId =
      'ca-app-pub-1293091196510342/6049905191';

  static const String aboutContent =
      '''
$baseAppName v1.0.0

$baseAppName is your ultimate financial companion, designed to help you monitor expenses and achieve your financial goals with ease. 

Our app provides a secure and intuitive interface to auto-detect and categorize your daily transactions from SMS and notifications, while also allowing you to manually add transactions yourself. It offers filtering and analysis to help you understand your spending and income across different categories.

Built with a commitment to simplicity and security, we strive to make financial management accessible to everyone.
''';

  static const String privacyPolicyContent = '''
Privacy Policy for Finzo (Smart Money Tracker)

Effective Date: June 18, 2026

Finzo ("we", "our", or "the app") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how Finzo collects, uses, stores, processes, and protects user data.

Information We Access

SMS Access
Finzo requests access to SMS messages only after obtaining explicit user consent through an in-app disclosure and Android permission request.
The app accesses and processes only transaction-related SMS messages associated with:
* Bank transactions
* UPI payments
* Debit card transactions
* Credit card transactions
* Financial account activity

SMS access is used strictly for:
* Automatic expense tracking
* Income detection
* Transaction categorization
* Financial summaries and insights
* Core app functionality

The app does not access, process, or use:
* Personal conversations
* OTP messages
* Authentication codes
* Non-financial SMS messages

Notification Access
Finzo may request Notification Access permission to detect financial transaction notifications from supported:
* Banking applications
* UPI applications
* Payment applications
* Financial service providers

Notification access is used only for:
* Automatic transaction detection
* Expense tracking
* Income tracking
* Transaction categorization
* Financial insights

The app does not process:
* Personal chat notifications
* Social media notifications
* Email notifications
* Non-financial notifications
* Personal communications

Only transaction-related financial notifications are used for expense tracking features.

Account Information
When users sign in using Google Sign-In, Finzo may access:
* Email address
* Google account identifier

This information is used only for:
* Authentication
* Account management
* Data synchronization
* Security purposes

Users may also use supported app features through guest access where available.

Profile Photos
Users may optionally upload a profile image. Profile images are used only for account personalization and are not publicly shared.

Device Information
The app and integrated services may collect limited device-related information such as:
* Device identifiers
* Advertising identifiers
* Crash reports
* Performance diagnostics

This information is used only for:
* Security
* App stability
* Performance monitoring
* Advertising services

AI Processing and Transaction Analysis
To provide automatic expense tracking and transaction categorization, Finzo may securely transmit transaction-related SMS messages and financial transaction notifications to cloud-based processing services that utilize a smart AI engine.

This processing may be used for:
* Transaction extraction
* Expense categorization
* Spending analysis
* Financial insights
* Transaction understanding

Only financial transaction data required for these features is processed.
The app does not transmit or process:
* Personal conversations
* OTP messages
* Authentication codes
* Non-financial SMS messages
* Personal notifications

Transaction-related data is processed only after the user provides explicit consent through the in-app disclosure and permission flow.
AI-powered analysis is used solely for providing expense tracking, categorization, and financial insight features.
User data is never sold to advertisers or unrelated third parties.

How We Use Information
Information is used only to:
* Provide automatic expense tracking
* Detect and categorize transactions
* Generate financial summaries and analytics
* Improve app functionality
* Maintain authentication services
* Ensure security and reliability

We do not sell personal user data.

Advertising
Finzo may display advertisements through third-party advertising services such as Google AdMob.
Advertising providers may collect:
* Device identifiers
* Advertising ID
* App interaction data
* Approximate location information

This information may be used to provide personalized or non-personalized advertisements.

For more information about Google's advertising practices, visit:
https://policies.google.com/technologies/ads

Data Storage and Security
We implement reasonable technical and organizational measures designed to protect user information from unauthorized access, disclosure, misuse, or alteration.
Sensitive transaction-related information is processed securely and used only for providing expense tracking and financial analysis features.
While we strive to protect user information, no method of electronic transmission or storage is completely secure, and absolute security cannot be guaranteed.

Data Sharing
Finzo does not sell, rent, or trade personal information.
Data may be shared only:
* With service providers necessary for app functionality
* With cloud-based processing services that utilize a smart AI engine solely for transaction extraction, categorization, expense analysis, and financial insights
* When required by law
* To comply with legal obligations
* To protect users, prevent fraud, or maintain platform security

User Control and Permissions
Users may:
* Disable SMS permissions through Android settings
* Disable Notification Access through Android settings
* Delete their account and associated app data
* Stop using the app at any time

Please note that automatic transaction detection, SMS-based expense tracking, notification-based transaction detection, and related financial insight features may not function properly if required permissions are disabled.
Manual transaction entry remains available for supported app features.

Data Deletion
Users may request deletion of their account and associated app data by contacting:
Email: hbpraveen311@gmail.com

Deletion requests are generally processed within 7 days.
Certain records may be retained where required for security, fraud prevention, legal compliance, or dispute resolution.

Children's Privacy
Finzo is not intended for children under 13 years of age.
We do not knowingly collect personal information from children under 13.

Changes to This Privacy Policy
We may update this Privacy Policy from time to time. Any changes will be reflected on this page with an updated effective date.

Contact Us
If you have any questions regarding this Privacy Policy, please contact:
Email: hbpraveen311@gmail.com
''';

  static const String termsAndConditionsContent =
      '''
Terms and Conditions

By using $baseAppName, you agree to the following terms:

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
