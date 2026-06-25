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
# Privacy Policy for Finzo (Smart Money Tracker)

**Effective Date:** June 25, 2026

Finzo ("we", "our", or "the app") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how Finzo collects, uses, stores, processes, and protects user data.

## Information We Access

### SMS Access

Finzo requests access to SMS messages only after obtaining your explicit consent through an in-app disclosure and Android permission request.

The app accesses and processes only financial transaction-related SMS messages, including:

* Bank transaction alerts
* UPI payment messages
* Debit card transaction messages
* Credit card transaction messages
* Financial account activity

SMS access is used solely to provide:

* Automatic expense tracking
* Income detection
* Transaction categorization
* Financial summaries
* Spending analytics
* Core app functionality

All SMS processing is performed locally on your device using rule-based parsing. Financial SMS content is **not transmitted to external AI services or cloud-based processing systems**.

The app does not process or use:

* Personal conversations
* OTP messages
* Authentication codes
* Promotional SMS
* Non-financial SMS messages

---

### Notification Access

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

Only financial transaction notifications required for expense tracking are processed.

---

### Google Sign-In

When you sign in using Google Sign-In, Finzo may access:

* Email address
* Google account identifier

This information is used only for:

* Authentication
* Account management
* Secure cloud synchronization

Where supported, users may also use guest access.

---

### Profile Images

Users may optionally upload a profile image for personalization.

Profile images are not publicly shared.

---

### Device Information

The app and integrated services may collect limited device-related information, including:

* Device identifiers
* Advertising ID
* Crash reports
* Performance diagnostics

This information is used only for:

* App stability
* Security
* Performance monitoring
* Advertising services

---

## How Your Data Is Processed

Transaction-related SMS messages and financial notifications are processed **locally on your device** using built-in parsing logic.

Finzo does **not** send your SMS messages or financial notifications to external AI services or cloud-based transaction analysis services.

Only data required for synchronization between your devices may be stored securely in your cloud account after authentication.

---

## How We Use Information

Information is used only to:

* Automatically detect financial transactions
* Track expenses and income
* Generate financial summaries and insights
* Synchronize your data
* Improve app functionality
* Maintain security and reliability

We do **not** sell your personal information.

---

## Advertising

Finzo may display advertisements using third-party advertising providers such as Google AdMob.

Advertising providers may collect:

* Advertising ID
* Device identifiers
* App interaction data
* Approximate location information

This information may be used to display personalized or non-personalized advertisements.

For more information, visit:

https://policies.google.com/technologies/ads

---

## Data Storage and Security

We implement reasonable technical and organizational measures to protect your information against unauthorized access, disclosure, alteration, or misuse.

Financial transaction information is processed securely and used only for providing expense tracking and budgeting features.

Although we strive to protect your information, no method of electronic storage or transmission is completely secure.

---

## Data Sharing

Finzo does **not** sell, rent, or trade personal information.

Information may be shared only:

* With service providers necessary to operate the app
* To synchronize user data across devices
* When required by law
* To comply with legal obligations
* To prevent fraud or protect users

Finzo does **not** share SMS messages or financial transaction content with third-party AI services.

---

## User Control

You may:

* Disable SMS permission through Android Settings
* Disable Notification Access
* Delete your account
* Delete your app data
* Stop using the app at any time

Disabling required permissions may prevent automatic transaction detection. Manual transaction entry remains available where supported.

---

## Data Deletion

You may request deletion of your account and associated cloud data by contacting:

**Email:** [hbpraveen311@gmail.com](mailto:hbpraveen311@gmail.com)

Deletion requests are generally processed within 7 days, except where information must be retained to comply with legal obligations or prevent fraud.

---

## Children's Privacy

Finzo is not intended for children under 13 years of age.

We do not knowingly collect personal information from children under 13.

---

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time.

Any changes will be reflected on this page with an updated effective date.

---

## Contact Us

If you have any questions about this Privacy Policy, please contact:

**Email:** [hbpraveen311@gmail.com](mailto:hbpraveen311@gmail.com)
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
