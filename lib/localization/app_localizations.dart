import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  // ==================== COMMON ====================
  String get appName => isArabic ? 'صيدليتي' : 'My Pharmacy';
  String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get error => isArabic ? 'خطأ' : 'Error';
  String get success => isArabic ? 'نجاح' : 'Success';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get yes => isArabic ? 'نعم' : 'Yes';
  String get no => isArabic ? 'لا' : 'No';
  String get ok => isArabic ? 'حسناً' : 'OK';
  String get search => isArabic ? 'بحث' : 'Search';
  String get noData => isArabic ? 'لا توجد بيانات' : 'No data available';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get refresh => isArabic ? 'تحديث' : 'Refresh';
  String get back => isArabic ? 'رجوع' : 'Back';
  String get next => isArabic ? 'التالي' : 'Next';
  String get done => isArabic ? 'تم' : 'Done';
  String get submit => isArabic ? 'إرسال' : 'Submit';
  String get update => isArabic ? 'تحديث' : 'Update';
  String get view => isArabic ? 'عرض' : 'View';
  String get details => isArabic ? 'التفاصيل' : 'Details';
  String get all => isArabic ? 'الكل' : 'All';
  String get none => isArabic ? 'لا شيء' : 'None';
  String get select => isArabic ? 'اختر' : 'Select';
  String get selected => isArabic ? 'محدد' : 'Selected';
  String get optional => isArabic ? 'اختياري' : 'Optional';
  String get required => isArabic ? 'مطلوب' : 'Required';
  String get note => isArabic ? 'ملاحظة' : 'Note';
  String get notes => isArabic ? 'ملاحظات' : 'Notes';
  String get status => isArabic ? 'الحالة' : 'Status';
  String get date => isArabic ? 'التاريخ' : 'Date';
  String get time => isArabic ? 'الوقت' : 'Time';
  String get today => isArabic ? 'اليوم' : 'Today';
  String get yesterday => isArabic ? 'أمس' : 'Yesterday';
  String get tomorrow => isArabic ? 'غداً' : 'Tomorrow';
  String get items => isArabic ? 'عناصر' : 'Items';
  String get item => isArabic ? 'عنصر' : 'Item';
  String get more => isArabic ? 'المزيد' : 'More';
  String get less => isArabic ? 'أقل' : 'Less';
  String get show => isArabic ? 'عرض' : 'Show';
  String get hide => isArabic ? 'إخفاء' : 'Hide';
  String get available => isArabic ? 'متاح' : 'Available';
  String get unavailable => isArabic ? 'غير متاح' : 'Unavailable';
  String get active => isArabic ? 'نشط' : 'Active';
  String get inactive => isArabic ? 'غير نشط' : 'Inactive';
  String get enabled => isArabic ? 'مفعل' : 'Enabled';
  String get disabled => isArabic ? 'معطل' : 'Disabled';

  // ==================== AUTH ====================
  String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get signUp => isArabic ? 'إنشاء حساب' : 'Sign Up';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get register => isArabic ? 'إنشاء حساب' : 'Register';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get emailAddress => isArabic ? 'البريد الإلكتروني' : 'Email Address';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get confirmPassword => isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get newPassword => isArabic ? 'كلمة المرور الجديدة' : 'New Password';
  String get currentPassword => isArabic ? 'كلمة المرور الحالية' : 'Current Password';
  String get forgotPassword => isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get resetPassword => isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset Password';
  String get sendResetEmail => isArabic ? 'إرسال رابط الاستعادة' : 'Send Reset Email';
  String get enterEmail => isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email';
  String get enterPassword => isArabic ? 'أدخل كلمة المرور' : 'Enter your password';
  String get invalidEmail => isArabic ? 'بريد إلكتروني غير صالح' : 'Invalid email';
  String get invalidPassword => isArabic ? 'كلمة المرور غير صالحة' : 'Invalid password';
  String get passwordResetSent => isArabic ? 'تم إرسال رابط استعادة كلمة المرور' : 'Password reset email sent';
  String get selectRole => isArabic ? 'اختر دورك' : 'Select Your Role';
  String get customer => isArabic ? 'عميل' : 'Customer';
  String get pharmacist => isArabic ? 'صيدلي' : 'Pharmacist';
  String get deliveryPerson => isArabic ? 'موظف توصيل' : 'Delivery Person';
  String get admin => isArabic ? 'مدير' : 'Admin';
  String get noAccount => isArabic ? 'ليس لديك حساب؟ سجل الآن' : "Don't have an account? Register";
  String get haveAccount => isArabic ? 'لديك حساب؟ سجل الدخول' : "Already have an account? Login";
  String get createAccount => isArabic ? 'إنشاء حساب جديد' : 'Create New Account';
  String get welcomeBack => isArabic ? 'مرحباً بعودتك!' : 'Welcome Back!';
  String get welcome => isArabic ? 'مرحباً' : 'Welcome';

  // ==================== NAVIGATION ====================
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get cart => isArabic ? 'السلة' : 'Cart';
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get profile => isArabic ? 'الملف الشخصي' : 'Profile';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get pharmacies => isArabic ? 'الصيدليات' : 'Pharmacies';
  String get products => isArabic ? 'المنتجات' : 'Products';
  String get reports => isArabic ? 'التقارير' : 'Reports';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get myOrders => isArabic ? 'طلباتي' : 'My Orders';
  String get myProfile => isArabic ? 'ملفي الشخصي' : 'My Profile';
  String get myCart => isArabic ? 'سلتي' : 'My Cart';

  // ==================== PRODUCTS ====================
  String get productName => isArabic ? 'اسم المنتج' : 'Product Name';
  String get productNameAr => isArabic ? 'اسم المنتج بالعربي' : 'Product Name (Arabic)';
  String get productNameEn => isArabic ? 'اسم المنتج بالإنجليزي' : 'Product Name (English)';
  String get price => isArabic ? 'السعر' : 'Price';
  String get quantity => isArabic ? 'الكمية' : 'Quantity';
  String get category => isArabic ? 'الفئة' : 'Category';
  String get description => isArabic ? 'الوصف' : 'Description';
  String get descriptionAr => isArabic ? 'الوصف بالعربي' : 'Description (Arabic)';
  String get descriptionEn => isArabic ? 'الوصف بالإنجليزي' : 'Description (English)';
  String get expiryDate => isArabic ? 'تاريخ الانتهاء' : 'Expiry Date';
  String get inStock => isArabic ? 'متوفر' : 'In Stock';
  String get outOfStock => isArabic ? 'نفذ المخزون' : 'Out of Stock';
  String get lowStock => isArabic ? 'مخزون منخفض' : 'Low Stock';
  String get addProduct => isArabic ? 'إضافة منتج' : 'Add Product';
  String get editProduct => isArabic ? 'تعديل المنتج' : 'Edit Product';
  String get deleteProduct => isArabic ? 'حذف المنتج' : 'Delete Product';
  String get searchProducts => isArabic ? 'البحث عن منتجات...' : 'Search products...';
  String get noProducts => isArabic ? 'لا توجد منتجات' : 'No products available';
  String get requiresPrescription => isArabic ? 'يتطلب وصفة طبية' : 'Requires Prescription';
  String get addToCart => isArabic ? 'أضف إلى السلة' : 'Add to Cart';
  String get addStock => isArabic ? 'إضافة مخزون' : 'Add Stock';
  String get manageBatches => isArabic ? 'إدارة الدفعات' : 'Manage Batches';
  String get batches => isArabic ? 'الدفعات' : 'Batches';
  String get batch => isArabic ? 'دفعة' : 'Batch';
  String get manufacturer => isArabic ? 'الشركة المصنعة' : 'Manufacturer';
  String get medicine => isArabic ? 'دواء' : 'Medicine';
  String get medicines => isArabic ? 'أدوية' : 'Medicines';
  String get drug => isArabic ? 'دواء' : 'Drug';
  String get dosage => isArabic ? 'الجرعة' : 'Dosage';
  String get instructions => isArabic ? 'التعليمات' : 'Instructions';
  String get sideEffects => isArabic ? 'الآثار الجانبية' : 'Side Effects';
  String get ingredients => isArabic ? 'المكونات' : 'Ingredients';
  String get usage => isArabic ? 'طريقة الاستخدام' : 'Usage';
  String get warnings => isArabic ? 'تحذيرات' : 'Warnings';
  String get storage => isArabic ? 'التخزين' : 'Storage';
  String get productImage => isArabic ? 'صورة المنتج' : 'Product Image';
  String get selectImage => isArabic ? 'اختر صورة' : 'Select Image';
  String get changeImage => isArabic ? 'تغيير الصورة' : 'Change Image';
  String get removeImage => isArabic ? 'إزالة الصورة' : 'Remove Image';
  String get unit => isArabic ? 'الوحدة' : 'Unit';
  String get units => isArabic ? 'وحدات' : 'Units';
  String get pieces => isArabic ? 'قطع' : 'Pieces';
  String get boxes => isArabic ? 'علب' : 'Boxes';
  String get tablets => isArabic ? 'أقراص' : 'Tablets';
  String get capsules => isArabic ? 'كبسولات' : 'Capsules';
  String get bottles => isArabic ? 'زجاجات' : 'Bottles';
  String get tubes => isArabic ? 'أنابيب' : 'Tubes';

  // ==================== CATEGORIES ====================
  String get painRelief => isArabic ? 'مسكنات الألم' : 'Pain Relief';
  String get antibiotics => isArabic ? 'المضادات الحيوية' : 'Antibiotics';
  String get vitamins => isArabic ? 'الفيتامينات' : 'Vitamins';
  String get skinCare => isArabic ? 'العناية بالبشرة' : 'Skin Care';
  String get babyProducts => isArabic ? 'منتجات الأطفال' : 'Baby Products';
  String get firstAid => isArabic ? 'الإسعافات الأولية' : 'First Aid';
  String get digestive => isArabic ? 'الجهاز الهضمي' : 'Digestive';
  String get respiratory => isArabic ? 'الجهاز التنفسي' : 'Respiratory';
  String get cardiovascular => isArabic ? 'القلب والأوعية الدموية' : 'Cardiovascular';
  String get diabetes => isArabic ? 'السكري' : 'Diabetes';
  String get eyeCare => isArabic ? 'العناية بالعين' : 'Eye Care';
  String get dentalCare => isArabic ? 'العناية بالأسنان' : 'Dental Care';
  String get hairCare => isArabic ? 'العناية بالشعر' : 'Hair Care';
  String get supplements => isArabic ? 'المكملات الغذائية' : 'Supplements';
  String get herbal => isArabic ? 'أعشاب طبية' : 'Herbal';
  String get personalCare => isArabic ? 'العناية الشخصية' : 'Personal Care';
  String get medicalDevices => isArabic ? 'الأجهزة الطبية' : 'Medical Devices';
  String get other => isArabic ? 'أخرى' : 'Other';

  // ==================== CART ====================
  String get yourCart => isArabic ? 'سلتك' : 'Your Cart';
  String get emptyCart => isArabic ? 'السلة فارغة' : 'Your cart is empty';
  String get addItemsToCart => isArabic ? 'ابدأ بإضافة الأدوية للمتابعة' : 'Start adding medicines to continue';
  String get total => isArabic ? 'المجموع' : 'Total';
  String get subtotal => isArabic ? 'المجموع الفرعي' : 'Subtotal';
  String get tax => isArabic ? 'الضريبة' : 'Tax';
  String get deliveryFee => isArabic ? 'رسوم التوصيل' : 'Delivery Fee';
  String get discount => isArabic ? 'الخصم' : 'Discount';
  String get grandTotal => isArabic ? 'المجموع الكلي' : 'Grand Total';
  String get checkout => isArabic ? 'إتمام الشراء' : 'Checkout';
  String get remove => isArabic ? 'إزالة' : 'Remove';
  String get prescriptionAttached => isArabic ? 'الوصفة مرفقة' : 'Prescription attached';
  String get pendingApproval => isArabic ? 'في انتظار موافقة الصيدلي' : 'Pending pharmacist approval';
  String get approved => isArabic ? 'تمت الموافقة' : 'Approved by pharmacist';
  String get rejected => isArabic ? 'مرفوض' : 'Rejected';
  String get clearCart => isArabic ? 'إفراغ السلة' : 'Clear Cart';
  String get continueShopping => isArabic ? 'متابعة التسوق' : 'Continue Shopping';
  String get itemsInCart => isArabic ? 'عناصر في السلة' : 'Items in cart';

  // ==================== ORDERS ====================
  String get orderDetails => isArabic ? 'تفاصيل الطلب' : 'Order Details';
  String get orderId => isArabic ? 'رقم الطلب' : 'Order ID';
  String get orderNumber => isArabic ? 'رقم الطلب' : 'Order Number';
  String get orderDate => isArabic ? 'تاريخ الطلب' : 'Order Date';
  String get orderStatus => isArabic ? 'حالة الطلب' : 'Order Status';
  String get noOrders => isArabic ? 'لم تقم بأي طلبات بعد' : 'You have not placed any orders yet';
  String get placeOrder => isArabic ? 'تأكيد الطلب' : 'Place Order';
  String get cancelOrder => isArabic ? 'إلغاء الطلب' : 'Cancel Order';
  String get orderCancelled => isArabic ? 'تم إلغاء الطلب' : 'Order cancelled';
  String get orderPlaced => isArabic ? 'تم تقديم الطلب' : 'Order placed successfully';
  String get deliveryAddress => isArabic ? 'عنوان التوصيل' : 'Delivery Address';
  String get houseNumber => isArabic ? 'رقم المنزل/المبنى' : 'House/Building Number';
  String get roadNumber => isArabic ? 'رقم الشارع' : 'Road Number';
  String get blockNumber => isArabic ? 'رقم المربع' : 'Block Number';
  String get additionalDirections => isArabic ? 'توجيهات إضافية' : 'Additional Directions';
  String get orderHistory => isArabic ? 'سجل الطلبات' : 'Order History';
  String get trackOrder => isArabic ? 'تتبع الطلب' : 'Track Order';
  String get reorder => isArabic ? 'إعادة الطلب' : 'Reorder';
  String get orderTotal => isArabic ? 'إجمالي الطلب' : 'Order Total';
  String get estimatedDelivery => isArabic ? 'وقت التوصيل المتوقع' : 'Estimated Delivery';
  String get placedOn => isArabic ? 'تم الطلب في' : 'Placed on';

  // Order statuses
  String get statusAwaitingConfirmation => isArabic ? 'في انتظار التأكيد' : 'Awaiting Confirmation';
  String get statusProcessing => isArabic ? 'قيد المعالجة' : 'Processing';
  String get statusReadyForPickup => isArabic ? 'جاهز للاستلام' : 'Ready for Pickup';
  String get statusOutForDelivery => isArabic ? 'في الطريق للتوصيل' : 'Out for Delivery';
  String get statusDelivered => isArabic ? 'تم التوصيل' : 'Delivered';
  String get statusCancelled => isArabic ? 'ملغي' : 'Cancelled';
  String get statusPending => isArabic ? 'قيد الانتظار' : 'Pending';
  String get statusConfirmed => isArabic ? 'مؤكد' : 'Confirmed';

  // ==================== CANCEL ORDER ====================
  String get cancelOrderTitle => isArabic ? 'إلغاء الطلب' : 'Cancel Order';
  String get cancelOrderConfirm => isArabic ? 'هل أنت متأكد من إلغاء هذا الطلب؟' : 'Are you sure you want to cancel this order?';
  String get cancelReason => isArabic ? 'سبب الإلغاء (اختياري)' : 'Reason for cancellation (optional)';
  String get cancelReasonHint => isArabic ? 'مثال: غيرت رأيي، طلبت بالخطأ...' : 'e.g., Changed my mind, Ordered by mistake...';
  String get keepOrder => isArabic ? 'إبقاء الطلب' : 'Keep Order';
  String get orderCancelledSuccess => isArabic ? 'تم إلغاء الطلب بنجاح' : 'Order cancelled successfully';
  String get changedYourMind => isArabic ? 'غيرت رأيك؟' : 'Changed your mind?';
  String get canCancelMessage => isArabic ? 'يمكنك إلغاء هذا الطلب لأنه لم يتم تجهيزه بعد.' : 'You can cancel this order since it hasn\'t been prepared yet.';
  String get orderAlreadyCancelled => isArabic ? 'تم إلغاء هذا الطلب' : 'This order has been cancelled';
  String get cannotCancelMessage => isArabic ? 'الطلب قيد التجهيز/التوصيل. لا يمكن إلغاؤه.' : 'Order is being prepared/delivered. Cannot be cancelled.';

  // ==================== EXPIRY TRACKER ====================
  String get expiryTracker => isArabic ? 'تتبع الصلاحية' : 'Expiry Tracker';
  String get noExpiryData => isArabic ? 'لا توجد منتجات بمعلومات صلاحية' : 'No products with expiry information found';
  String get expired => isArabic ? 'منتهي الصلاحية' : 'Expired';
  String get expiresToday => isArabic ? 'ينتهي اليوم' : 'Expires today';
  String get expiresTomorrow => isArabic ? 'ينتهي غداً' : 'Expires tomorrow';
  String expiresInDays(int days) => isArabic ? 'ينتهي خلال $days أيام' : 'Expires in $days days';
  String get markAsFinished => isArabic ? 'تم الانتهاء منه' : 'Mark as Finished';
  String get confirmCompletion => isArabic ? 'تأكيد الانتهاء' : 'Confirm Completion';
  String get finishedMedicineQuestion => isArabic ? 'هل انتهيت من استخدام هذا الدواء؟' : 'Have you finished using this medicine?';
  String get willBeRemoved => isArabic ? 'سيتم إزالته من قائمة تتبع الصلاحية.' : 'It will be removed from your expiry tracker list.';
  String get yesDone => isArabic ? 'نعم، انتهيت' : 'Yes, I\'m done';
  String removedFromList(String name) => isArabic ? 'تم إزالة "$name" من القائمة' : '"$name" removed from list';
  String get purchasedOn => isArabic ? 'تاريخ الشراء' : 'Purchased on';
  String get daysRemaining => isArabic ? 'الأيام المتبقية' : 'Days Remaining';
  String get expirySoon => isArabic ? 'قريب الانتهاء' : 'Expiring Soon';

  // ==================== REPORTS ====================
  String get reportsAnalytics => isArabic ? 'التقارير والتحليلات' : 'Reports & Analytics';
  String get period => isArabic ? 'الفترة' : 'Period';
  String get daily => isArabic ? 'يومي' : 'Daily';
  String get weekly => isArabic ? 'أسبوعي' : 'Weekly';
  String get monthly => isArabic ? 'شهري' : 'Monthly';
  String get yearly => isArabic ? 'سنوي' : 'Yearly';
  String get keyMetrics => isArabic ? 'المؤشرات الرئيسية' : 'Key Metrics';
  String get totalOrders => isArabic ? 'إجمالي الطلبات' : 'Total Orders';
  String get revenue => isArabic ? 'الإيرادات' : 'Revenue';
  String get completed => isArabic ? 'مكتمل' : 'Completed';
  String get pending => isArabic ? 'قيد الانتظار' : 'Pending';
  String get analytics => isArabic ? 'التحليلات' : 'Analytics';
  String get ordersStatus => isArabic ? 'حالة الطلبات' : 'Orders Status';
  String get inventoryAlerts => isArabic ? 'تنبيهات المخزون' : 'Inventory Alerts';
  String get nearExpiry => isArabic ? 'قريب الانتهاء' : 'Near Expiry';
  String get topSellingProducts => isArabic ? 'الأكثر مبيعاً' : 'Top Selling Products';
  String get fastMoving => isArabic ? 'سريعة الحركة - أعد الطلب' : 'Fast Moving - Restock Soon';
  String get cancelledOrders => isArabic ? 'الطلبات الملغية' : 'Cancelled Orders';
  String get noInventoryAlerts => isArabic ? 'لا توجد تنبيهات للمخزون' : 'No inventory alerts';
  String get tapToView => isArabic ? 'اضغط للعرض' : 'Tap to view';
  String get viewAll => isArabic ? 'عرض الكل' : 'View All';
  String get currentStock => isArabic ? 'المخزون الحالي' : 'Current Stock';
  String get sales => isArabic ? 'المبيعات' : 'Sales';
  String get daysLeft => isArabic ? 'الأيام المتبقية' : 'Days Left';
  String get restockImmediately => isArabic ? 'أعد الطلب فوراً!' : 'Restock immediately!';
  String get considerRestocking => isArabic ? 'فكر في إعادة الطلب قريباً' : 'Consider restocking soon';
  String get urgent => isArabic ? 'عاجل' : 'URGENT';
  String get quantityToAdd => isArabic ? 'الكمية المراد إضافتها' : 'Quantity to Add';
  String get enterQuantity => isArabic ? 'أدخل الكمية' : 'Enter quantity';
  String addedUnits(int qty, String name) => isArabic ? 'تمت إضافة $qty وحدة إلى $name' : 'Added $qty units to $name';
  String get statistics => isArabic ? 'الإحصائيات' : 'Statistics';
  String get averageOrderValue => isArabic ? 'متوسط قيمة الطلب' : 'Average Order Value';
  String get totalRevenue => isArabic ? 'إجمالي الإيرادات' : 'Total Revenue';
  String get totalProducts => isArabic ? 'إجمالي المنتجات' : 'Total Products';
  String get totalCustomers => isArabic ? 'إجمالي العملاء' : 'Total Customers';

  // ==================== AI PREDICTIONS ====================
  String get aiPredictions => isArabic ? 'تنبؤات الذكاء الاصطناعي' : 'AI-Powered Predictions';
  String get highDemandForecast => isArabic ? 'توقعات المنتجات عالية الطلب' : 'High-demand products forecast';
  String get addProductsToSeePredictions => isArabic ? 'أضف منتجات لرؤية التنبؤات...' : 'Add products to see AI predictions...';
  String get veryHigh => isArabic ? 'عالي جداً' : 'Very High';
  String get high => isArabic ? 'عالي' : 'High';
  String get moderate => isArabic ? 'متوسط' : 'Moderate';
  String get low => isArabic ? 'منخفض' : 'Low';
  String get confidence => isArabic ? 'نسبة الثقة' : 'Confidence';
  String get demand => isArabic ? 'الطلب' : 'Demand';
  String get prediction => isArabic ? 'التنبؤ' : 'Prediction';

  // ==================== PROFILE ====================
  String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get name => isArabic ? 'الاسم' : 'Name';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  String get firstName => isArabic ? 'الاسم الأول' : 'First Name';
  String get lastName => isArabic ? 'الاسم الأخير' : 'Last Name';
  String get phone => isArabic ? 'الهاتف' : 'Phone';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get mobileNumber => isArabic ? 'رقم الجوال' : 'Mobile Number';
  String get address => isArabic ? 'العنوان' : 'Address';
  String get city => isArabic ? 'المدينة' : 'City';
  String get area => isArabic ? 'المنطقة' : 'Area';
  String get country => isArabic ? 'الدولة' : 'Country';
  String get darkMode => isArabic ? 'الوضع الداكن' : 'Dark Mode';
  String get lightMode => isArabic ? 'الوضع الفاتح' : 'Light Mode';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get aboutUs => isArabic ? 'عنا' : 'About Us';
  String get contactUs => isArabic ? 'تواصل معنا' : 'Contact Us';
  String get privacyPolicy => isArabic ? 'سياسة الخصوصية' : 'Privacy Policy';
  String get termsOfService => isArabic ? 'شروط الخدمة' : 'Terms of Service';
  String get helpSupport => isArabic ? 'المساعدة والدعم' : 'Help & Support';
  String get faq => isArabic ? 'الأسئلة الشائعة' : 'FAQ';
  String get rateApp => isArabic ? 'قيم التطبيق' : 'Rate App';
  String get shareApp => isArabic ? 'شارك التطبيق' : 'Share App';
  String get version => isArabic ? 'الإصدار' : 'Version';
  String get profileUpdated => isArabic ? 'تم تحديث الملف الشخصي' : 'Profile updated successfully';
  String get profilePhoto => isArabic ? 'صورة الملف الشخصي' : 'Profile Photo';
  String get changePhoto => isArabic ? 'تغيير الصورة' : 'Change Photo';
  String get removePhoto => isArabic ? 'إزالة الصورة' : 'Remove Photo';
  String get takePicture => isArabic ? 'التقاط صورة' : 'Take Picture';
  String get chooseFromGallery => isArabic ? 'اختر من المعرض' : 'Choose from Gallery';
  String get accountSettings => isArabic ? 'إعدادات الحساب' : 'Account Settings';
  String get notificationSettings => isArabic ? 'إعدادات الإشعارات' : 'Notification Settings';
  String get appearance => isArabic ? 'المظهر' : 'Appearance';
  String get general => isArabic ? 'عام' : 'General';
  String get security => isArabic ? 'الأمان' : 'Security';
  String get deleteAccount => isArabic ? 'حذف الحساب' : 'Delete Account';
  String get deleteAccountConfirm => isArabic ? 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.' : 'Are you sure you want to delete your account? This action cannot be undone.';

  // ==================== DELIVERY ====================
  String get myDeliveries => isArabic ? 'توصيلاتي' : 'My Deliveries';
  String get availableOrders => isArabic ? 'الطلبات المتاحة' : 'Available Orders';
  String get acceptOrder => isArabic ? 'قبول الطلب' : 'Accept Order';
  String get startDelivery => isArabic ? 'بدء التوصيل' : 'Start Delivery';
  String get completeDelivery => isArabic ? 'إتمام التوصيل' : 'Complete Delivery';
  String get deliveryCompleted => isArabic ? 'تم التوصيل' : 'Delivery Completed';
  String get customerInfo => isArabic ? 'معلومات العميل' : 'Customer Info';
  String get pharmacyInfo => isArabic ? 'معلومات الصيدلية' : 'Pharmacy Info';
  String get callCustomer => isArabic ? 'اتصل بالعميل' : 'Call Customer';
  String get openMaps => isArabic ? 'فتح الخريطة' : 'Open Maps';
  String get navigation => isArabic ? 'التنقل' : 'Navigation';
  String get distance => isArabic ? 'المسافة' : 'Distance';
  String get deliveryTime => isArabic ? 'وقت التوصيل' : 'Delivery Time';
  String get pickupLocation => isArabic ? 'موقع الاستلام' : 'Pickup Location';
  String get dropoffLocation => isArabic ? 'موقع التسليم' : 'Dropoff Location';
  String get assignedDelivery => isArabic ? 'موظف التوصيل' : 'Assigned Delivery';
  String get noDeliveries => isArabic ? 'لا توجد توصيلات' : 'No deliveries available';
  String get deliveryStatus => isArabic ? 'حالة التوصيل' : 'Delivery Status';
  String get pickedUp => isArabic ? 'تم الاستلام' : 'Picked Up';
  String get onTheWay => isArabic ? 'في الطريق' : 'On the Way';
  String get arrived => isArabic ? 'وصل' : 'Arrived';

  // ==================== PRESCRIPTIONS ====================
  String get prescriptions => isArabic ? 'الوصفات الطبية' : 'Prescriptions';
  String get prescription => isArabic ? 'وصفة طبية' : 'Prescription';
  String get uploadPrescription => isArabic ? 'رفع وصفة طبية' : 'Upload Prescription';
  String get viewPrescription => isArabic ? 'عرض الوصفة' : 'View Prescription';
  String get approvePrescription => isArabic ? 'الموافقة على الوصفة' : 'Approve Prescription';
  String get rejectPrescription => isArabic ? 'رفض الوصفة' : 'Reject Prescription';
  String get prescriptionRequired => isArabic ? 'هذا المنتج يتطلب وصفة طبية' : 'This product requires a prescription';
  String get noPrescriptions => isArabic ? 'لا توجد وصفات طبية' : 'No prescriptions';
  String get prescriptionApproved => isArabic ? 'تمت الموافقة على الوصفة' : 'Prescription approved';
  String get prescriptionRejected => isArabic ? 'تم رفض الوصفة' : 'Prescription rejected';
  String get pendingPrescriptions => isArabic ? 'الوصفات المعلقة' : 'Pending Prescriptions';
  String get approvedPrescriptions => isArabic ? 'الوصفات الموافق عليها' : 'Approved Prescriptions';
  String get rejectedPrescriptions => isArabic ? 'الوصفات المرفوضة' : 'Rejected Prescriptions';

  // ==================== LOCATION ====================
  String get selectLocation => isArabic ? 'اختر الموقع' : 'Select Location';
  String get useCurrentLocation => isArabic ? 'استخدم موقعي الحالي' : 'Use My Current Location';
  String get selectOnMap => isArabic ? 'اختر على الخريطة' : 'Select on Map';
  String get confirmLocation => isArabic ? 'تأكيد الموقع' : 'Confirm Location';
  String get currentLocation => isArabic ? 'الموقع الحالي' : 'Current Location';
  String get searchLocation => isArabic ? 'البحث عن موقع' : 'Search Location';
  String get locationPermission => isArabic ? 'إذن الموقع' : 'Location Permission';
  String get locationPermissionDenied => isArabic ? 'تم رفض إذن الموقع' : 'Location permission denied';
  String get enableLocation => isArabic ? 'تفعيل الموقع' : 'Enable Location';
  String get locationServices => isArabic ? 'خدمات الموقع' : 'Location Services';
  String get latitude => isArabic ? 'خط العرض' : 'Latitude';
  String get longitude => isArabic ? 'خط الطول' : 'Longitude';
  String get coordinates => isArabic ? 'الإحداثيات' : 'Coordinates';

  // ==================== PAYMENT ====================
  String get payment => isArabic ? 'الدفع' : 'Payment';
  String get paymentMethod => isArabic ? 'طريقة الدفع' : 'Payment Method';
  String get cashOnDelivery => isArabic ? 'الدفع عند الاستلام' : 'Cash on Delivery';
  String get creditCard => isArabic ? 'بطاقة ائتمان' : 'Credit Card';
  String get debitCard => isArabic ? 'بطاقة خصم' : 'Debit Card';
  String get bankTransfer => isArabic ? 'تحويل بنكي' : 'Bank Transfer';
  String get wallet => isArabic ? 'المحفظة' : 'Wallet';
  String get payNow => isArabic ? 'ادفع الآن' : 'Pay Now';
  String get payLater => isArabic ? 'ادفع لاحقاً' : 'Pay Later';
  String get paymentSuccessful => isArabic ? 'تم الدفع بنجاح' : 'Payment Successful';
  String get paymentFailed => isArabic ? 'فشل الدفع' : 'Payment Failed';
  String get paymentPending => isArabic ? 'الدفع معلق' : 'Payment Pending';
  String get invoice => isArabic ? 'الفاتورة' : 'Invoice';
  String get receipt => isArabic ? 'الإيصال' : 'Receipt';
  String get downloadInvoice => isArabic ? 'تحميل الفاتورة' : 'Download Invoice';
  String get printReceipt => isArabic ? 'طباعة الإيصال' : 'Print Receipt';

  // ==================== PHARMACY ====================
  String get pharmacy => isArabic ? 'صيدلية' : 'Pharmacy';
  String get pharmacyName => isArabic ? 'اسم الصيدلية' : 'Pharmacy Name';
  String get pharmacyAddress => isArabic ? 'عنوان الصيدلية' : 'Pharmacy Address';
  String get pharmacyPhone => isArabic ? 'هاتف الصيدلية' : 'Pharmacy Phone';
  String get pharmacyHours => isArabic ? 'ساعات العمل' : 'Working Hours';
  String get openNow => isArabic ? 'مفتوح الآن' : 'Open Now';
  String get closed => isArabic ? 'مغلق' : 'Closed';
  String get open24Hours => isArabic ? 'مفتوح 24 ساعة' : 'Open 24 Hours';
  String get viewProducts => isArabic ? 'عرض المنتجات' : 'View Products';
  String get selectPharmacy => isArabic ? 'اختر صيدلية' : 'Select Pharmacy';
  String get nearbyPharmacies => isArabic ? 'صيدليات قريبة' : 'Nearby Pharmacies';
  String get searchPharmacies => isArabic ? 'البحث عن صيدليات' : 'Search Pharmacies';
  String get noPharmacies => isArabic ? 'لا توجد صيدليات' : 'No pharmacies found';
  String get pharmacyDetails => isArabic ? 'تفاصيل الصيدلية' : 'Pharmacy Details';

  // ==================== ADMIN ====================
  String get adminPanel => isArabic ? 'لوحة الإدارة' : 'Admin Panel';
  String get dashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get manageUsers => isArabic ? 'إدارة المستخدمين' : 'Manage Users';
  String get managePharmacies => isArabic ? 'إدارة الصيدليات' : 'Manage Pharmacies';
  String get manageProducts => isArabic ? 'إدارة المنتجات' : 'Manage Products';
  String get manageOrders => isArabic ? 'إدارة الطلبات' : 'Manage Orders';
  String get manageDelivery => isArabic ? 'إدارة التوصيل' : 'Manage Delivery';
  String get manageCustomers => isArabic ? 'إدارة العملاء' : 'Manage Customers';
  String get systemSettings => isArabic ? 'إعدادات النظام' : 'System Settings';
  String get users => isArabic ? 'المستخدمون' : 'Users';
  String get addUser => isArabic ? 'إضافة مستخدم' : 'Add User';
  String get editUser => isArabic ? 'تعديل المستخدم' : 'Edit User';
  String get deleteUser => isArabic ? 'حذف المستخدم' : 'Delete User';
  String get userDetails => isArabic ? 'تفاصيل المستخدم' : 'User Details';
  String get role => isArabic ? 'الدور' : 'Role';
  String get permissions => isArabic ? 'الصلاحيات' : 'Permissions';
  String get activate => isArabic ? 'تفعيل' : 'Activate';
  String get deactivate => isArabic ? 'إلغاء التفعيل' : 'Deactivate';
  String get ban => isArabic ? 'حظر' : 'Ban';
  String get unban => isArabic ? 'إلغاء الحظر' : 'Unban';

  // ==================== REGISTRATION ====================
  String get personalInfo => isArabic ? 'المعلومات الشخصية' : 'Personal Information';
  String get accountInfo => isArabic ? 'معلومات الحساب' : 'Account Information';
  String get enterFullName => isArabic ? 'أدخل اسمك الكامل' : 'Enter your full name';
  String get enterPhoneNumber => isArabic ? 'أدخل رقم هاتفك' : 'Enter your phone number';
  String get enterAddress => isArabic ? 'أدخل عنوانك' : 'Enter your address';
  String get agreeToTerms => isArabic ? 'أوافق على الشروط والأحكام' : 'I agree to the Terms and Conditions';
  String get registrationSuccessful => isArabic ? 'تم التسجيل بنجاح' : 'Registration successful';
  String get registrationFailed => isArabic ? 'فشل التسجيل' : 'Registration failed';

  // ==================== MESSAGES ====================
  String get somethingWentWrong => isArabic ? 'حدث خطأ ما' : 'Something went wrong';
  String get tryAgain => isArabic ? 'حاول مرة أخرى' : 'Try again';
  String get noInternetConnection => isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';
  String get sessionExpired => isArabic ? 'انتهت الجلسة، الرجاء تسجيل الدخول مرة أخرى' : 'Session expired, please login again';
  String get insufficientStock => isArabic ? 'المخزون غير كافٍ' : 'Insufficient stock';
  String availableStock(int qty) => isArabic ? 'المتوفر: $qty' : 'Available: $qty';
  String get productNotFound => isArabic ? 'المنتج غير موجود' : 'Product not found';
  String get emailNotFound => isArabic ? 'البريد الإلكتروني غير موجود' : 'Email not found';
  String get wrongPassword => isArabic ? 'كلمة المرور خاطئة' : 'Wrong password';
  String get accountDisabled => isArabic ? 'الحساب معطل' : 'Account disabled';
  String get emailAlreadyInUse => isArabic ? 'البريد الإلكتروني مستخدم بالفعل' : 'Email already in use';
  String get weakPassword => isArabic ? 'كلمة المرور ضعيفة' : 'Password is too weak';
  String get passwordMinLength => isArabic ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters';
  String get fillAllFields => isArabic ? 'يرجى ملء جميع الحقول' : 'Please fill all fields';
  String get invalidPhoneNumber => isArabic ? 'رقم هاتف غير صالح' : 'Invalid phone number';
  String get savedSuccessfully => isArabic ? 'تم الحفظ بنجاح' : 'Saved successfully';
  String get deletedSuccessfully => isArabic ? 'تم الحذف بنجاح' : 'Deleted successfully';
  String get updatedSuccessfully => isArabic ? 'تم التحديث بنجاح' : 'Updated successfully';
  String get addedSuccessfully => isArabic ? 'تمت الإضافة بنجاح' : 'Added successfully';
  String get operationFailed => isArabic ? 'فشلت العملية' : 'Operation failed';
  String get confirmDelete => isArabic ? 'هل أنت متأكد من الحذف؟' : 'Are you sure you want to delete?';
  String get cannotBeUndone => isArabic ? 'لا يمكن التراجع عن هذا الإجراء' : 'This action cannot be undone';
  String get pleaseWait => isArabic ? 'يرجى الانتظار...' : 'Please wait...';
  String get processingRequest => isArabic ? 'جاري معالجة الطلب...' : 'Processing request...';

  // ==================== NOTIFICATIONS ====================
  String get allNotifications => isArabic ? 'جميع الإشعارات' : 'All Notifications';
  String get noNotifications => isArabic ? 'لا توجد إشعارات' : 'No notifications';
  String get markAllAsRead => isArabic ? 'تحديد الكل كمقروء' : 'Mark all as read';
  String get clearAll => isArabic ? 'مسح الكل' : 'Clear All';
  String get newOrder => isArabic ? 'طلب جديد' : 'New Order';
  String get orderUpdate => isArabic ? 'تحديث الطلب' : 'Order Update';
  String get promotions => isArabic ? 'العروض' : 'Promotions';
  String get reminders => isArabic ? 'التذكيرات' : 'Reminders';
  String get orderNotifications => isArabic ? 'إشعارات الطلبات' : 'Order Notifications';
  String get promotionalNotifications => isArabic ? 'إشعارات العروض' : 'Promotional Notifications';
  String get pushNotifications => isArabic ? 'الإشعارات الفورية' : 'Push Notifications';
  String get emailNotifications => isArabic ? 'إشعارات البريد الإلكتروني' : 'Email Notifications';
  String get smsNotifications => isArabic ? 'إشعارات الرسائل النصية' : 'SMS Notifications';

  // ==================== REQUESTS ====================
  String get requests => isArabic ? 'الطلبات' : 'Requests';
  String get pendingRequests => isArabic ? 'الطلبات المعلقة' : 'Pending Requests';
  String get approvedRequests => isArabic ? 'الطلبات الموافق عليها' : 'Approved Requests';
  String get rejectedRequests => isArabic ? 'الطلبات المرفوضة' : 'Rejected Requests';
  String get newRequest => isArabic ? 'طلب جديد' : 'New Request';
  String get requestDetails => isArabic ? 'تفاصيل الطلب' : 'Request Details';
  String get approveRequest => isArabic ? 'الموافقة على الطلب' : 'Approve Request';
  String get rejectRequest => isArabic ? 'رفض الطلب' : 'Reject Request';
  String get requestApproved => isArabic ? 'تمت الموافقة على الطلب' : 'Request approved';
  String get requestRejected => isArabic ? 'تم رفض الطلب' : 'Request rejected';
  String get requestProduct => isArabic ? 'طلب منتج' : 'Request Product';
  String get requestedBy => isArabic ? 'مطلوب من قبل' : 'Requested by';
  String get requestDate => isArabic ? 'تاريخ الطلب' : 'Request Date';

  // ==================== INVOICE ====================
  String get invoiceNumber => isArabic ? 'رقم الفاتورة' : 'Invoice Number';
  String get invoiceDate => isArabic ? 'تاريخ الفاتورة' : 'Invoice Date';
  String get dueDate => isArabic ? 'تاريخ الاستحقاق' : 'Due Date';
  String get billedTo => isArabic ? 'فاتورة إلى' : 'Billed To';
  String get from => isArabic ? 'من' : 'From';
  String get to => isArabic ? 'إلى' : 'To';
  String get itemDescription => isArabic ? 'وصف العنصر' : 'Item Description';
  String get unitPrice => isArabic ? 'سعر الوحدة' : 'Unit Price';
  String get amount => isArabic ? 'المبلغ' : 'Amount';
  String get thankYou => isArabic ? 'شكراً لك!' : 'Thank You!';
  String get paidInFull => isArabic ? 'مدفوعة بالكامل' : 'Paid in Full';

  // ==================== TIME PERIODS ====================
  String get lastWeek => isArabic ? 'الأسبوع الماضي' : 'Last Week';
  String get lastMonth => isArabic ? 'الشهر الماضي' : 'Last Month';
  String get lastYear => isArabic ? 'السنة الماضية' : 'Last Year';
  String get thisWeek => isArabic ? 'هذا الأسبوع' : 'This Week';
  String get thisMonth => isArabic ? 'هذا الشهر' : 'This Month';
  String get thisYear => isArabic ? 'هذه السنة' : 'This Year';
  String get custom => isArabic ? 'مخصص' : 'Custom';
  String get selectDateRange => isArabic ? 'اختر نطاق التاريخ' : 'Select Date Range';
  String get startDate => isArabic ? 'تاريخ البداية' : 'Start Date';
  String get endDate => isArabic ? 'تاريخ النهاية' : 'End Date';

  // ==================== CONFIRMATION DIALOGS ====================
  String get areYouSure => isArabic ? 'هل أنت متأكد؟' : 'Are you sure?';
  String get confirmAction => isArabic ? 'تأكيد الإجراء' : 'Confirm Action';
  String get unsavedChanges => isArabic ? 'تغييرات غير محفوظة' : 'Unsaved Changes';
  String get discardChanges => isArabic ? 'تجاهل التغييرات' : 'Discard Changes';
  String get saveChanges => isArabic ? 'حفظ التغييرات' : 'Save Changes';
  String get stay => isArabic ? 'البقاء' : 'Stay';
  String get leave => isArabic ? 'مغادرة' : 'Leave';

  // ==================== EMPTY STATES ====================
  String get noResults => isArabic ? 'لا توجد نتائج' : 'No results found';
  String get noItemsFound => isArabic ? 'لم يتم العثور على عناصر' : 'No items found';
  String get emptyList => isArabic ? 'القائمة فارغة' : 'List is empty';
  String get nothingHere => isArabic ? 'لا يوجد شيء هنا' : 'Nothing here';
  String get startAdding => isArabic ? 'ابدأ بالإضافة' : 'Start adding';

  // ==================== CURRENCY ====================
  String get currency => isArabic ? 'OMR' : 'OMR';
  String get omanRial => isArabic ? 'ريال عماني' : 'Omani Rial';
  String formatPrice(double price) => isArabic ? '$price ر.ع' : '$price OMR';

  // ==================== COMMON MEDICINES (for search/display) ====================
  String get paracetamol => isArabic ? 'باراسيتامول' : 'Paracetamol';
  String get ibuprofen => isArabic ? 'ايبوبروفين' : 'Ibuprofen';
  String get aspirin => isArabic ? 'أسبرين' : 'Aspirin';
  String get amoxicillin => isArabic ? 'أموكسيسيلين' : 'Amoxicillin';
  String get omeprazole => isArabic ? 'أوميبرازول' : 'Omeprazole';
  String get metformin => isArabic ? 'ميتفورمين' : 'Metformin';
  String get amlodipine => isArabic ? 'أملوديبين' : 'Amlodipine';
  String get cetirizine => isArabic ? 'سيتيريزين' : 'Cetirizine';
  String get loratadine => isArabic ? 'لوراتادين' : 'Loratadine';
  String get simvastatin => isArabic ? 'سيمفاستاتين' : 'Simvastatin';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
