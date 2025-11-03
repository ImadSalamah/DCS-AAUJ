// ignore_for_file: dead_code
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/language_provider.dart' hide UserRole;
import '../loginpage.dart' show UserRole, LoginPage;
import 'role_guard.dart';
import '../Shared/waiting_list_page.dart';
import '../Doctor/examined_patients_page.dart';
import '../Doctor/doctor_sidebar.dart';
import '../notifications_page.dart';
import '../Doctor/prescription_page.dart';
import '../Doctor/doctor_xray_request_page.dart';
import '../Doctor/clinical_procedures_form.dart';
import 'package:http/http.dart' as http;

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRole: UserRole.doctor,
      child: _SupervisorDashboardContent(),
    );
  }
}

class _SupervisorDashboardContent extends StatefulWidget {
  const _SupervisorDashboardContent();

  @override
  State<_SupervisorDashboardContent> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<_SupervisorDashboardContent> {
  // Helper to build a feature box. Replace with your actual implementation if needed.
  Widget _buildFeatureBox(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 350;
    final isTablet = width >= 600;
    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 18 : 12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 24 : (isTablet ? 40 : 30),
                  color: color,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : (isTablet ? 18 : 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<String> allowedFeatures = [];
  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  // No Firebase, use REST API
  String? _supervisorUid;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _supervisorName = '';
  String _supervisorImageUrl = '';
  bool _isLoading = true;
  bool _hasError = false;
  final int _retryCount = 0;
  final int _maxRetries = 3;
  bool _isSidebarVisible = false;

  bool hasNewNotification = false;

  final Map<String, Map<String, String>> _translations = {
    'supervisor': {'ar': 'مشرف', 'en': 'Supervisor'},
    'initial_examination': {'ar': 'الفحص الأولي', 'en': 'Initial Examination'},
    'students_evaluation': {'ar': 'تقييم الطلاب', 'en': 'Students Evaluation'},
    'waiting_list': {'ar': 'قائمة الانتظار', 'en': 'Waiting List'},
    'appointments': {'ar': 'المواعيد', 'en': 'Appointments'},
    'reports': {'ar': 'التقارير', 'en': 'Reports'},
    'profile': {'ar': 'الملف الشخصي', 'en': 'Profile'},
    'history': {'ar': 'السجل', 'en': 'History'},
    'xray_request': {'ar': 'طلب أشعة', 'en': 'X-Ray Request'},
    'clinical_procedures': {'ar': 'الإجراءات السريرية', 'en': 'Clinical Procedures'},
    'examined_patients': {'ar': 'المرضى المفحوصين', 'en': 'Examined Patients'},
    'prescription': {'ar': 'الوصفات الطبية', 'en': 'Prescription'},
    'error_loading_data': {'ar': 'خطأ في تحميل البيانات', 'en': 'Error loading data'},
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'close': {'ar': 'إغلاق', 'en': 'Close'},
    'signing_out': {'ar': 'جاري تسجيل الخروج...', 'en': 'Signing out...'},
    'sign_out_error': {'ar': 'خطأ في تسجيل الخروج', 'en': 'Sign out error'},
    'hide_sidebar': {'ar': 'إخفاء القائمة الجانبية', 'en': 'Hide sidebar'},
    'show_sidebar': {'ar': 'إظهار القائمة الجانبية', 'en': 'Show sidebar'},
  };

  @override
  void initState() {
    super.initState();
    _loadSupervisorData();
    _listenForNotifications();
  }

  Future<void> _loadSupervisorData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('userData');
      if (userDataJson == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }
      final userData = json.decode(userDataJson);
      _supervisorUid = userData['USER_ID']?.toString();
      
      // 🔥 التعديل: استخدام endpoint الأطباء بدلاً من المستخدمين
      final response = await http.get(Uri.parse('http://localhost:3000/doctors/$_supervisorUid'));
      debugPrint('API response.statusCode: ${response.statusCode}');
      debugPrint('API response.body: ${response.body}');
      
      if (response.statusCode == 200) {
        final freshUser = json.decode(response.body);
        debugPrint('freshUser map: $freshUser');
        
        // تحديث SharedPreferences
        await prefs.setString('userData', json.encode(freshUser));
        _updateSupervisorData(freshUser);
        
        // 🔥 التعديل: تبسيط معالجة allowedFeatures
        _processAllowedFeatures(freshUser);
        
      } else {
        // fallback للبيانات المحفوظة
        _updateSupervisorData(userData);
        _processAllowedFeatures(userData);
      }
    } catch (e) {
      debugPrint('❌ Error in _loadSupervisorData: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // 🔥 NEW: دالة منفصلة لمعالجة allowedFeatures
  void _processAllowedFeatures(Map<String, dynamic> userData) {
    List<String> features = [];
    
    try {
      // المحاولة 1: من الحقل الجديد allowedFeatures
      if (userData['allowedFeatures'] is List) {
        features = List<String>.from(userData['allowedFeatures']);
        debugPrint('✅ تم تحميل الفيتشرز من allowedFeatures: $features');
      }
      // المحاولة 2: من الحقل القديم ALLOWED_FEATURES
      else if (userData['ALLOWED_FEATURES'] is List) {
        features = List<String>.from(userData['ALLOWED_FEATURES']);
        debugPrint('✅ تم تحميل الفيتشرز من ALLOWED_FEATURES: $features');
      }
      // المحاولة 3: من نص JSON
      else if (userData['ALLOWED_FEATURES'] is String) {
        try {
          final parsed = json.decode(userData['ALLOWED_FEATURES']);
          if (parsed is List) {
            features = List<String>.from(parsed);
            debugPrint('✅ تم تحميل الفيتشرز من نص JSON: $features');
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحويل JSON: $e');
        }
      }
      
      debugPrint('📊 الفيتشرز النهائية: $features');
      
    } catch (e) {
      debugPrint('❌ خطأ في معالجة الفيتشرز: $e');
      features = [];
    }
    
    setState(() {
      allowedFeatures = features;
    });
  }
 
  void _updateSupervisorData(Map data) {
    // جلب الاسم الكامل من FULL_NAME أو تركيبة الأسماء
    final fullName = (data['FULL_NAME'] ?? '').toString().trim();
    String name = fullName;
    if (name.isEmpty) {
      final firstName = data['FIRST_NAME']?.toString().trim() ?? '';
      final fatherName = data['FATHER_NAME']?.toString().trim() ?? '';
      final grandfatherName = data['GRANDFATHER_NAME']?.toString().trim() ?? '';
      final familyName = data['FAMILY_NAME']?.toString().trim() ?? '';
      name = [
        if (firstName.isNotEmpty) firstName,
        if (fatherName.isNotEmpty) fatherName,
        if (grandfatherName.isNotEmpty) grandfatherName,
        if (familyName.isNotEmpty) familyName,
      ].join(' ');
    }

    // جلب الصورة من IMAGE
    final imageData = data['IMAGE']?.toString().trim() ?? '';
    String imageUrl = '';
    if (imageData.isNotEmpty && (imageData.startsWith('http://') || imageData.startsWith('https://'))) {
      imageUrl = imageData;
    }

    setState(() {
      _supervisorName = name.isNotEmpty
          ? _isArabic(context) ? "د. $name" : "د. $name"
          : _translate(context, 'supervisor');
      _supervisorImageUrl = imageUrl;
      _isLoading = false;
      _hasError = false;
    });
  }

  Future<void> _loadSupervisorDataOnce() async {
    await _loadSupervisorData();
    if (_hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate(context, 'error_loading_data')),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void showDashboardBanner(String message, {Color backgroundColor = Colors.green}) {
    ScaffoldMessenger.of(context).clearMaterialBanners();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
            child: Text(
              _translate(context, 'close'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _listenForNotifications() {
    // يمكن إضافة منطق الاستماع للإشعارات لاحقاً
  }

  String _translate(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.currentLocale.languageCode] ?? key;
  }

  bool _isArabic(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.currentLocale.languageCode == 'ar';
  }

  String _getErrorMessage() {
    return _translate(context, 'error_loading_data');
  }

  Future<void> _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_translate(context, 'signing_out')),
              ],
            ),
          );
        },
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pop();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_translate(context, 'sign_out_error')}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 350;
    final isLargeScreen = mediaQuery.size.width >= 900;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).clearMaterialBanners();
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(
            'Dental Clinics',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              if (isLargeScreen) {
                setState(() {
                  _isSidebarVisible = !_isSidebarVisible;
                });
              } else {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
            tooltip: _isSidebarVisible
                ? _translate(context, 'hide_sidebar')
                : _translate(context, 'show_sidebar'),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: hasNewNotification ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      hasNewNotification = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsPage()),
                    );
                  },
                ),
                if (hasNewNotification)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.language, color: Colors.white),
              onPressed: () => languageProvider.toggleLanguage(),
            ),
            IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.white),
            )
          ],
        ),
        drawer: !isLargeScreen
            ? DoctorSidebar(
                primaryColor: primaryColor,
                userRole: 'doctor',
                accentColor: accentColor,
                userName: _supervisorName,
                userImageUrl: _supervisorImageUrl,
                onLogout: _signOut,
                parentContext: context,
                translate: _translate,
                doctorUid: _supervisorUid ?? '',
                allowedFeatures: allowedFeatures,
              )
            : null,
        body: Stack(
          children: [
            if (isLargeScreen && _isSidebarVisible)
              Directionality(
                textDirection: _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
                child: SizedBox(
                  width: 260,
                  child: DoctorSidebar(
                    primaryColor: primaryColor,
                    userRole: 'doctor',
                    accentColor: accentColor,
                    userName: _supervisorName,
                    userImageUrl: _supervisorImageUrl,
                    onLogout: _signOut,
                    parentContext: context,
                    collapsed: false,
                    translate: _translate,
                    doctorUid: _supervisorUid ?? '',
                    allowedFeatures: allowedFeatures,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                left: (isLargeScreen && _isSidebarVisible && !_isArabic(context)) ? 260 : 0,
                right: (isLargeScreen && _isSidebarVisible && _isArabic(context)) ? 260 : 0,
              ),
              child: Directionality(
                textDirection: _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
                child: _buildBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(_getErrorMessage(), style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadSupervisorDataOnce,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(_translate(context, 'retry'), style: const TextStyle(color: Colors.white)),
            ),
            if (_retryCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('($_retryCount/$_maxRetries)', style: const TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      );
    }

    // 🔥 إضافة طباعة للتحقق من الفيتشرز
    debugPrint('🎯 الفيتشرز النهائية للعرض: $allowedFeatures');

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final allFeatureBoxes = [
          {
            'key': 'waiting_list',
            'icon': Icons.list_alt,
            'title': _translate(context, 'waiting_list'),
            'color': primaryColor,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WaitingListPage(userRole: 'doctor'),
                ),
              );
            }
          },
          {
            'key': 'clinical_procedures_form',
            'icon': Icons.medical_information,
            'title': _isArabic(context) ? 'نموذج الإجراءات السريرية' : 'Clinical Procedures Form',
            'color': Colors.redAccent,
            'onTap': () {
              if (_supervisorUid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClinicalProceduresForm(uid: _supervisorUid!),
                  ),
                );
              }
            }
          },
         {
  'key': 'examined_patients',
  'icon': Icons.check_circle,
  'title': _translate(context, 'examined_patients'),
  'color': Colors.teal,
  'onTap': () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorExaminedPatientsPage(
          doctorName: _supervisorName,
          doctorImageUrl: _supervisorImageUrl,
          currentUserId: _supervisorUid,
          userAllowedFeatures: allowedFeatures,
        ),
      ),
    );
  }
},
          {
            'key': 'prescription',
            'icon': Icons.medical_services,
            'title': _translate(context, 'prescription'),
            'color': Colors.deepPurple,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
             builder: (context) => PrescriptionPage(
  uid: _supervisorUid!,
),
                ),
              );
            }
          },
          {
            'key': 'xray_request',
            'icon': Icons.camera_alt,
            'title': _translate(context, 'xray_request'),
            'color': Colors.orange,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorXrayRequestPage(),
                ),
              );
            }
          },
        ];
        
        // 🔥 التعديل: تصفية الفيتشرز بناءً على allowedFeatures
        final features = allFeatureBoxes.where((f) => allowedFeatures.contains(f['key'])).toList();
        
        debugPrint('📋 عدد الفيتشرز المتاحة للعرض: ${features.length}');
        for (var f in features) {
          debugPrint('   - ${f['key']}: ${f['title']}');
        }

        final width = constraints.maxWidth;
        final isSmallScreen = width < 350;
        final isWide = width > 900;
        final isTablet = width >= 600 && width <= 900;
        final crossAxisCount = isWide ? 4 : (isTablet ? 3 : 2);
        final gridChildAspectRatio = isWide ? 1.1 : (isTablet ? 1.2 : 1.1);
        
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: mediaQuery.padding.bottom + (isSmallScreen ? 10 : 20),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    height: isSmallScreen ? 210 : (isWide ? 210 : (isTablet ? 250 : 230)),
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('lib/assets/backgrownd.png'),
                        fit: BoxFit.fill,
                      ),
                      color: const Color(0x4D000000),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0x33000000),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              (_supervisorImageUrl.isNotEmpty && (_supervisorImageUrl.startsWith('http://') || _supervisorImageUrl.startsWith('https://')))
                                  ? CircleAvatar(
                                      radius: isSmallScreen
                                          ? 30
                                          : (isWide ? 55 : (isTablet ? 45 : 40)),
                                      backgroundColor: Colors.white.withAlpha(204),
                                      child: ClipOval(
                                        child: Image.network(
                                          _supervisorImageUrl,
                                          width: isSmallScreen
                                              ? 60
                                              : (isWide ? 110 : (isTablet ? 90 : 80)),
                                          height: isSmallScreen
                                              ? 60
                                              : (isWide ? 110 : (isTablet ? 90 : 80)),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: isSmallScreen
                                          ? 30
                                          : (isWide ? 55 : (isTablet ? 45 : 40)),
                                      backgroundColor: Colors.white.withAlpha(204),
                                      child: Icon(
                                        Icons.person,
                                        size: isSmallScreen
                                            ? 30
                                            : (isWide ? 55 : (isTablet ? 45 : 40)),
                                        color: accentColor,
                                      ),
                                    ),
                              SizedBox(height: isWide ? 30 : (isTablet ? 25 : 15)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  _supervisorName,
                                  style: TextStyle(
                                    fontSize: isSmallScreen
                                        ? 16
                                        : (isWide ? 28 : (isTablet ? 22 : 20)),
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 🔥 عرض رسالة إذا لم توجد فيتشرز
                  if (features.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _isArabic(context) 
                                ? 'لا توجد صلاحيات متاحة حالياً'
                                : 'No features available at the moment',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: features.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: gridChildAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final feature = features[index];
                          return _buildFeatureBox(
                            context,
                            feature['icon'] as IconData,
                            feature['title'] as String,
                            feature['color'] as Color,
                            feature['onTap'] as VoidCallback,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}