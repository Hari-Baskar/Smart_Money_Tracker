class AppStrings {
  static const String appName = "₹ Smart Money Tracker";
  static const String appIconPath = "assets/images/app_icon.png";

  // AdMob Ad Unit IDs
  static const String androidBannerAdUnitId =
      'ca-app-pub-1293091196510342/9937804038';
  static const String androidNativeAdUnitId =
      'ca-app-pub-1293091196510342/2096796864';

  static const String aboutContent = '''
Smart Money Tracker v1.0.0

Smart Money Tracker is your ultimate financial companion, designed to help you monitor expenses, manage budgets, and achieve your financial goals with ease. 

Our app provides a secure and intuitive interface to track your daily transactions, offering powerful insights and automated categorization to give you full control over your personal finances.

Built with a commitment to simplicity and security, we strive to make financial management accessible to everyone.
''';

  static const String privacyPolicyContent = '''
Privacy Policy for Smart Money Tracker

Effective Date: May 26, 2026

Smart Money Tracker (“we”, “our”, or “the app”) respects your privacy and is committed to protecting your personal information.

This Privacy Policy explains how Smart Money Tracker collects, uses, stores, processes, and protects user data.

1. Information We Collect and Access

SMS Access

Smart Money Tracker requests access to SMS messages only after obtaining explicit user consent through an in-app disclosure and consent screen.

The app is designed to identify and process only transactional SMS messages related to:

* Bank transactions
* UPI payments
* Credit and debit card activity
* Financial account alerts
* Expense and income notifications

SMS access is used strictly for:

* Automatic expense tracking
* Income detection
* Transaction categorization
* Financial summaries and insights
* Core app functionality

The app does not intentionally process, categorize, or transmit:

* Personal conversations
* OTP messages
* Authentication codes
* Private chats
* Non-financial SMS messages

Notification Access

Smart Money Tracker may request Notification Access permission to detect financial transaction notifications from:

* Banks
* UPI applications
* Payment apps
* Financial service providers

This allows automatic transaction tracking without requiring manual entry.

Account Information

When users sign in using Google Sign-In, the app may access:

* Email address
* User account identifier

This information is used only for:

* Authentication
* Account management
* Secure syncing of user data

Users may also use the app through guest access where supported.

Photos

Users may optionally upload a profile image within the app. Profile photos are used only for account personalization and are not publicly shared.

Device Information

The app and integrated services may collect limited device-related information such as:

* Device identifiers
* Advertising identifiers
* Crash logs
* App performance data

This information may be used for:

* Security
* App stability
* Performance monitoring
* Advertising services

2. AI Processing and Transaction Analysis

Smart Money Tracker may securely transmit limited transaction-related SMS content to Google Gemini AI services for:

* Automated expense tracking
* Transaction categorization
* Financial insights
* Spending analysis

Only transaction-related financial SMS messages are processed for these features.

Personal conversations, OTP messages, authentication codes, and non-financial SMS messages are not intentionally processed or transmitted.

Google Gemini AI services are used solely for transaction analysis and financial categorization features. Transaction-related data transmitted for analysis is processed securely and is not sold for advertising purposes.

3. Permissions Used

To support automatic expense tracking, the app may use the following Android permissions:

* READ_SMS
  Allows the app to read existing transactional SMS messages to detect and categorize financial transactions.

* RECEIVE_SMS
  Allows the app to detect incoming transactional SMS alerts in real time for automatic expense tracking.

* Notification Access
  Allows the app to detect financial transaction notifications from supported financial and payment applications.

Users may revoke these permissions at any time through Android device settings.

4. How We Use Information

The accessed information is used only to:

* Provide automatic expense tracking
* Detect and categorize transactions
* Generate financial summaries and analytics
* Improve app functionality and user experience
* Maintain authentication and account services
* Ensure app security and stability

We do not sell personal user data to third parties.

5. Data Sharing and Third-Party Services

Data may be processed or shared with trusted service providers required for core app functionality, including:

* Google Firebase
  (authentication, secure cloud storage, analytics)

* Google AdMob
  (advertising services)

* Google Gemini AI services
  (transaction categorization and financial insights)

These services process data securely and only to support app functionality.

We do not sell, rent, or trade personal information to advertisers or unrelated third parties.

Data may also be disclosed if required by law, legal process, or to protect app security and prevent fraud.

6. Advertising

Smart Money Tracker may display third-party advertisements using advertising platforms such as Google AdMob.

Advertising providers may collect limited information including:

* Device identifiers
* Advertising ID
* App interaction data
* Approximate location information

This information may be used to provide personalized or non-personalized advertisements.

For more information about how Google uses data, visit:

https://policies.google.com/technologies/ads

7. Data Security

We implement security measures designed to protect user data against unauthorized access, misuse, alteration, or disclosure.

Sensitive transaction-related information is transmitted securely using encryption in transit and is processed only for providing expense tracking and financial analysis features.

While we strive to protect user information, no method of electronic transmission or storage is completely secure.

8. Data Storage and User Control

User data may be securely stored using Google Firebase infrastructure.

Users retain control over their data and may:

* Disable SMS permissions at any time
* Disable Notification Access permissions
* Use the app without enabling SMS access
* Delete their account and associated data
* Stop using the app at any time

Some features may not function properly if permissions are disabled.

9. Data Deletion

Users may request deletion of their account and associated app data by contacting:

[hbpraveen311@gmail.com](mailto:hbpraveen311@gmail.com)

Deletion requests are generally processed within 7 days.

Certain limited records may be temporarily retained where required for security, fraud prevention, or legal compliance.

10. Children’s Privacy

Smart Money Tracker is not intended for children under 13 years of age.

We do not knowingly collect personal information from children.

11. Changes to This Privacy Policy

We may update this Privacy Policy from time to time.

Any updates will be reflected on this page with an updated effective date.

12. Contact Us

If you have any questions regarding this Privacy Policy, you may contact us at:

[hbpraveen311@gmail.com](mailto:hbpraveen311@gmail.com)

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
