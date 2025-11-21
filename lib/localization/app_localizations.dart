import 'package:flutter/material.dart';

/// Simple AppLocalizations stub - language switching removed
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // All strings return English by default
  bool get isArabic => false;
  
  // Add all the string getters that are used in the app
  String get language => 'Language';
  String get arabic => 'Arabic';
  String get english => 'English';
  String get customer => 'Customer';
  String get pharmacist => 'Pharmacist';
  String get deliveryPerson => 'Delivery Person';
  String get admin => 'Admin';
  String get login => 'Login';
  String get email => 'Email';
  String get password => 'Password';
  String get forgotPassword => 'Forgot Password';
  String get selectRole => 'Select Role';
  String get resetPassword => 'Reset Password';
  String get registrationSuccessful => 'Registration Successful';
  String get registrationFailed => 'Registration Failed';
  String get currentPassword => 'Current Password';
  String get newPassword => 'New Password';
  String get confirmPassword => 'Confirm Password';
  String get cancel => 'Cancel';
  String get saveChanges => 'Save Changes';
  String get error => 'Error';
  String get loading => 'Loading';
  String get profileUpdated => 'Profile Updated';
  String get operationFailed => 'Operation Failed';
  String get fullName => 'Full Name';
  String get phoneNumber => 'Phone Number';
  String get address => 'Address';
  String get optional => 'Optional';
  String get darkMode => 'Dark Mode';
  String get notificationSettings => 'Notification Settings';
  String get trackOrder => 'Track Order';
  String get orderHistory => 'Order History';
  String get somethingWentWrong => 'Something went wrong';
  String get noOrders => 'No orders found';
  String get sessionExpired => 'Session expired. Please login again.';
  String get chatbotTitle => 'Chatbot';
  String get chatbotWelcome => 'Welcome! How can I help you?';
  String get chatbotShowHelp => 'Show Help';
  String get chatbotFrequentlyAsked => 'Frequently Asked Questions';
  String get chatbotQuickReplyHowToOrder => 'How to order?';
  String get chatbotQuickReplyTrackOrder => 'Track order';
  String get chatbotQuickReplyPrescription => 'Prescription';
  String get chatbotQuickReplyHelp => 'Help';
  String get pharmacistChatbotGreetingResponse => 'Hello! I am your smart assistant. How can I help you today?';
  String get pharmacistChatbotQuickReplyProducts => 'Products';
  String get pharmacistChatbotQuickReplyOrders => 'Orders';
  String get pharmacistChatbotQuickReplyPrescriptions => 'Prescriptions';
  String get pharmacistChatbotQuickReplyReports => 'Reports';
  List<String> get chatbotGreetingKeywords => ['hello', 'hi', 'greetings'];
  List<String> get pharmacistChatbotExpiryKeywords => ['expiry', 'expired', 'delete'];
  
  // Product related
  String get category => 'Category';
  String get price => 'Price';
  String get prescriptionRequired => 'Prescription Required';
  String get uploadPrescription => 'Upload Prescription';
  String get addToCart => 'Add to Cart';
  String get prescriptionAttached => 'Prescription Attached';
  String get approved => 'Approved';
  String get pendingApproval => 'Pending Approval';
  String get insufficientStock => 'Insufficient Stock';
  String availableStock(int count) => 'Available: $count';
  String get remove => 'Remove';
  String get emptyCart => 'Your cart is empty';
  String get addItemsToCart => 'Add items to your cart';
  String get total => 'Total';
  String get ok => 'OK';
  String get checkout => 'Checkout';
  
  // Navigation
  String get pharmacies => 'Pharmacies';
  String get cart => 'Cart';
  String get orders => 'Orders';
  String get profile => 'Profile';
  String get logout => 'Logout';
  String get home => 'Home';
  String get products => 'Products';
  String get quantity => 'Quantity';
  
  // Order related
  String get cancelOrderTitle => 'Cancel Order';
  String get cancelOrderConfirm => 'Are you sure you want to cancel this order?';
  String get cancelReason => 'Reason for cancellation';
  String get cancelReasonHint => 'Enter reason (optional)';
  String get keepOrder => 'Keep Order';
  String get cancelOrder => 'Cancel Order';
  String get orderCancelledSuccess => 'Order cancelled successfully';
  String get orderDate => 'Order Date';
  String get deliveryAddress => 'Delivery Address';
  String get houseNumber => 'House Number';
  String get roadNumber => 'Road Number';
  String get additionalDirections => 'Additional Directions';
  String get changedYourMind => 'Changed your mind?';
  String get canCancelMessage => 'You can cancel this order';
  String get orderAlreadyCancelled => 'This order has already been cancelled';
  String get cannotCancelMessage => 'This order cannot be cancelled';
  String get close => 'Close';
  String get paymentMethod => 'Payment Method';
  
  // Delivery
  String get myDeliveries => 'My Deliveries';
  String get noDeliveries => 'No deliveries found';
  
  // Expiry tracker
  String get confirmCompletion => 'Confirm Completion';
  String get finishedMedicineQuestion => 'Have you finished this medicine?';
  String get willBeRemoved => 'It will be removed from your list';
  String get yesDone => 'Yes, I\'m done';
  String removedFromList(String name) => '$name removed from list';
  String get expiresToday => 'Expires Today';
  String get expiresTomorrow => 'Expires Tomorrow';
  String get expiryTracker => 'Expiry Tracker';
  String get refresh => 'Refresh';
  String get noExpiryData => 'No expiry data found';
  String get purchasedOn => 'Purchased On';
  String get markAsFinished => 'Mark as Finished';
  
  // Registration/Login
  String get signUp => 'Sign Up';
  String get enterFullName => 'Enter Full Name';
  String get emailAddress => 'Email Address';
  String get enterEmail => 'Enter Email';
  String get invalidEmail => 'Invalid Email';
  String get enterPhoneNumber => 'Enter Phone Number';
  String get enterPassword => 'Enter Password';
  String get haveAccount => 'Already have an account?';
  String get pleaseWait => 'Please wait...';
  String get sendResetEmail => 'Send Reset Email';
  
  // Pharmacy browser
  String get searchPharmacies => 'Search Pharmacies';
  String get noPharmacies => 'No pharmacies found';
  String get noResults => 'No results found';
  String get noProducts => 'No products found';
  String get requestProduct => 'Request Product';
  String get searchProducts => 'Search Products';
  
  // Chatbot
  String get chatbotFindPharmacy => 'Find Pharmacy';
  String get chatbotViewCart => 'View Cart';
  String get chatbotViewOrders => 'View Orders';
  List<String> get chatbotProductKeywords => ['product', 'products', 'medicine', 'medicines'];
  String get chatbotBrowseProducts => 'Browse Products';
  List<String> get chatbotOrderKeywords => ['order', 'orders', 'purchase', 'buy'];
  String get chatbotTrackOrder => 'Track Order';
  List<String> get chatbotAccountKeywords => ['account', 'profile', 'settings'];
  String get chatbotViewProfile => 'View Profile';
  List<String> get chatbotPrescriptionKeywords => ['prescription', 'prescriptions'];
  List<String> get chatbotDeliveryKeywords => ['delivery', 'deliver', 'shipping'];
  List<String> get chatbotPaymentKeywords => ['payment', 'pay', 'checkout'];
  List<String> get chatbotNavigationKeywords => ['navigate', 'go to', 'show me'];
  String get chatbotLoginRequired => 'Please login to use the chatbot';
  String get chatbotFAQHowToOrder => 'How to order?';
  String get chatbotFAQTrackOrder => 'How to track my order?';
  String get chatbotFAQPrescription => 'How to upload prescription?';
  String get chatbotFAQDelivery => 'What are delivery options?';
  String get chatbotFAQPayment => 'What payment methods are available?';
  String get chatbotTypeMessage => 'Type a message...';
  String get pharmacistChatbotViewProducts => 'View Products';
  String get pharmacistChatbotViewOrders => 'View Orders';
  String get pharmacistChatbotViewPrescriptions => 'View Prescriptions';
  String get pharmacistChatbotViewReports => 'View Reports';
  List<String> get pharmacistChatbotProductKeywords => ['product', 'products', 'add product'];
  String get pharmacistChatbotAddProduct => 'Add Product';
  List<String> get pharmacistChatbotOrderKeywords => ['order', 'orders'];
  List<String> get pharmacistChatbotPrescriptionKeywords => ['prescription', 'prescriptions'];
  String get pharmacistChatbotViewRequests => 'View Requests';
  List<String> get pharmacistChatbotRequestKeywords => ['request', 'requests'];
  List<String> get pharmacistChatbotReportKeywords => ['report', 'reports', 'analytics'];
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

