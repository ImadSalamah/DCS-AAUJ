// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/language_provider.dart' hide UserRole;
import 'package:shared_preferences/shared_preferences.dart';
import '../loginpage.dart' show UserRole, LoginPage;
import 'role_guard.dart';
import '../Student/student_add_patient_page.dart';
import '../Student/student_xray_upload_page.dart';
import '../Student/examined_patients_page.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRole: UserRole.dental_student,
      child: _StudentDashboardContent(),
    );
  }
}

class _StudentDashboardContent extends StatefulWidget {
  const _StudentDashboardContent();

  @override
  State<_StudentDashboardContent> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboardContent> {
  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);

  String _userName = '';
  String _userImageUrl = '';
  List<Map<String, dynamic>> assignedPatients = [];
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  final int _retryCount = 0;
  final int _maxRetries = 3;

  bool hasNewNotification = false;

  final Map<String, Map<String, String>> _translations = {
    'student_dashboard': {'ar': 'لوحة الطالب', 'en': 'Student Dashboard'},
    'view_examinations': {'ar': 'عرض الفحوصات', 'en': 'View Examinations'},
    'examine_patient': {'ar': 'فحص المريض', 'en': 'Examine Patient'},
    'add_patient': {'ar': 'إضافة مريض', 'en': 'Add Patient'},
    'notifications': {'ar': 'الإشعارات', 'en': 'Notifications'},
    'student': {'ar': 'طالب', 'en': 'Student'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
    'app_name': {
      'ar': 'عيادات أسنان الجامعة العربية الأمريكية',
      'en': 'Arab American University Dental Clinics'
    },
    'error_loading_data': {
      'ar': 'حدث خطأ في تحميل البيانات',
      'en': 'Error loading data'
    },
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'no_internet': {
      'ar': 'لا يوجد اتصال بالإنترنت',
      'en': 'No internet connection'
    },
    'server_error': {'ar': 'خطأ في السيرفر', 'en': 'Server error'},
    'no_notifications': {'ar': 'لا توجد إشعارات', 'en': 'No notifications'},
    'close': {'ar': 'إغلاق', 'en': 'Close'},
    'my_appointments': {'ar': 'مواعيدي', 'en': 'My Appointments'},
    'upload_xray': {'ar': 'رفع صورة الأشعة', 'en': 'Upload X-ray'},
  };

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
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
      final data = json.decode(userDataJson);
      // الاسم الكامل من FULL_NAME أو تركيبة الأسماء
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
      // الصورة من IMAGE إذا كانت رابط مباشر
      final imageData = data['IMAGE']?.toString().trim() ?? '';
      String imageUrl = '';
      if (imageData.isNotEmpty && (imageData.startsWith('http://') || imageData.startsWith('https://'))) {
        imageUrl = imageData;
      }
      setState(() {
        _userName = name.isNotEmpty ? name : _translate(context, 'student');
        _userImageUrl = imageUrl;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }


String _getCurrentUserId() {
  // محاولة جلب الـ user ID من الـ provider أو الـ shared preferences
  try {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (languageProvider.currentUserId != null && languageProvider.currentUserId!.isNotEmpty) {
      return languageProvider.currentUserId!;
    }
    
    // بديل: جلب من البيانات المحفوظة
    final prefs = SharedPreferences.getInstance();
    final userDataJson = prefs.then((prefs) => prefs.getString('userData'));
    final userData = json.decode(userDataJson as String);
    return userData['USER_ID']?.toString() ?? '';
    } catch (e) {
    debugPrint('Error getting user ID: $e');
  }
  
  return '';
}
  String _translate(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]![languageProvider.currentLocale.languageCode] ?? '';
  }

  bool _isArabic(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return languageProvider.currentLocale.languageCode == 'ar';
  }

  String _getErrorMessage() {
    return _translate(context, 'error_loading_data');
  }

  Future<void> _logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void showDashboardBanner(String message, {Color backgroundColor = Colors.green}) {
    ScaffoldMessenger.of(context).clearMaterialBanners();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notifications_active, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
              child: const Text('إغلاق'),
            ),
          ),
        ],
        forceActionsBelow: true,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).clearMaterialBanners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 350;

    return Directionality(
      textDirection: _isArabic(context) ? TextDirection.rtl : TextDirection.ltr,
      // ignore: deprecated_member_use
      child: WillPopScope(
        onWillPop: () async {
          ScaffoldMessenger.of(context).clearMaterialBanners();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(
              _translate(context, 'app_name'),
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: () => languageProvider.toggleLanguage(),
              ),
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
                      _showNotificationsDialog(context);
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
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
              )
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: primaryColor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _userImageUrl.isNotEmpty
                          ? CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.network(
                                  _userImageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 32,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: accentColor,
                              ),
                            ),
                      const SizedBox(height: 10),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _translate(context, 'student'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home, color: primaryColor),
                  title: Text(_translate(context, 'home')),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentDashboard(),
                      ),
                    );
                  },
                ),
      // في student_dashboard.dart - تصحيح السطر 385
                ListTile(
                  leading: Icon(Icons.assignment, color: primaryColor),
                  title: Text(_translate(context, 'view_examinations')),
                  onTap: () {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (!languageProvider.isEnglish) {
      languageProvider.setLocale(const Locale('en'));
    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
        builder: (context) => StudentExaminedPatientsPage( // ✅ غير الاسم هنا
          studentName: _userName,
          studentImageUrl: _userImageUrl,
          currentUserId: _getCurrentUserId(),
          userAllowedFeatures: const ['examined_patients'],
        ),
                      ),
                    );
                  },
                ),
               
            
              ],
            ),
          ),
          endDrawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: primaryColor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _userImageUrl.isNotEmpty
                          ? CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.network(
                                  _userImageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 32,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: accentColor,
                              ),
                            ),
                      const SizedBox(height: 10),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _translate(context, 'student'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.assignment, color: primaryColor),
                  title: Text(_translate(context, 'view_examinations')),
                  onTap: () {
                    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                    if (!languageProvider.isEnglish) {
                      languageProvider.setLocale(const Locale('en'));
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StudentExaminedPatientsPage()));
                  },
                ),
              
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.orange),
                  title: Text(_translate(context, 'notifications')),
                  onTap: () {
                    _showNotificationsDialog(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.home, color: primaryColor),
                  title: Text(_translate(context, 'home')),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentDashboard(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: Builder(
            builder: (context) {
              Future.microtask(() {
                final args = ModalRoute.of(context)?.settings.arguments;
                if (args is Map && args['showBanner'] == true) {
                  showDashboardBanner(args['bannerMessage'] ?? 'تمت قراءة الإشعار بنجاح');
                }
              });
              return _buildBody(context);
            },
          ),
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
            Text(
              _getErrorMessage(),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadStudentData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                _translate(context, 'retry'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (_retryCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '($_retryCount/$_maxRetries)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      );
    }

          final mediaQuery = MediaQuery.of(context);
          final isSmallScreen = mediaQuery.size.width < 350;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final gridCount = isWide ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
              return Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: mediaQuery.padding.bottom + 20),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(20),
                          height: isSmallScreen ? 180 : 200,
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage('lib/assets/backgrownd.png'),
                              fit: BoxFit.cover,
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
                                    _userImageUrl.isNotEmpty
                                        ? CircleAvatar(
                                            radius: isSmallScreen ? 30 : 40,
                                            backgroundColor: Colors.white.withAlpha((0.8 * 255).toInt()),
                                            child: ClipOval(
                                        child: Image.network(
                                          _userImageUrl,
                                                width: isSmallScreen ? 60 : 80,
                                                height: isSmallScreen ? 60 : 80,
                                                fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            size: isSmallScreen ? 30 : 40,
                                            color: accentColor,
                                          ),
                                              ),
                                            ),
                                          )
                                        : CircleAvatar(
                                            radius: isSmallScreen ? 30 : 40,
                                            backgroundColor: Colors.white.withAlpha((0.8 * 255).toInt()),
                                            child: Icon(
                                              Icons.person,
                                              size: isSmallScreen ? 30 : 40,
                                              color: accentColor,
                                            ),
                                          ),
                                    const SizedBox(height: 15),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        _userName,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _translate(context, 'student'),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: gridCount,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.1,
                            children: [
                              _buildFeatureBox(
                                context,
                                Icons.assignment,
                                _translate(context, 'view_examinations'),
                                primaryColor,
                                onTap: () {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (!languageProvider.isEnglish) {
      languageProvider.setLocale(const Locale('en'));
    }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
        builder: (context) => StudentExaminedPatientsPage(
          studentName: _userName,
          studentImageUrl: _userImageUrl,
          currentUserId: _getCurrentUserId(),
          userAllowedFeatures: const ['examined_patients'],
        ),
                                    ),
                                  );
                                },
                              ),
                              _buildFeatureBox(
                                context,
                          Icons.person_add,
                          _translate(context, 'add_patient'),
                          Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                builder: (context) => const StudentAddPatientPage(),
                                    ),
                                  );
                                },
                              ),
                      
                              _buildFeatureBox(
                                context,
                          Icons.camera_alt,
                          _translate(context, 'upload_xray'),
                          Colors.purple,
                          onTap: () async {
                            try {
                              final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                              final studentId = languageProvider.currentUserId;
                              
                              
                              if (studentId == null || studentId.isEmpty) {
                                // محاولة جلب المعرف من SharedPreferences كبديل
                                final prefs = await SharedPreferences.getInstance();
                                final userDataJson = prefs.getString('userData');
                                if (userDataJson != null) {
                                  final userData = json.decode(userDataJson);
                                  final fallbackStudentId = userData['USER_ID']?.toString();
                                  
                                  if (fallbackStudentId != null && fallbackStudentId.isNotEmpty) {
                                    // تحديث الـ Provider بالمعرف
                                    languageProvider.setUserId(fallbackStudentId);
                                    
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => StudentXrayUploadPage(studentId: fallbackStudentId),
                                      ),
                                    );
                                    return;
                                  }
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('يرجى تسجيل الدخول مرة أخرى'),
                                    backgroundColor: Colors.red,
                                  )
                                );
                                return;
                              }
                              
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => StudentXrayUploadPage(studentId: studentId),
                              ),
                            );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('حدث خطأ، يرجى المحاولة مرة أخرى'),
                                  backgroundColor: Colors.red,
                                )
                            );
                            }
                          },
                        ),
                   
                      ],
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

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_translate(context, 'notifications')),
          content: notifications.isEmpty
              ? Text(_translate(context, 'no_notifications'))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(notification['title'] ?? ''),
                        subtitle: Text(notification['body'] ?? ''),
                        trailing: notification['timestamp'] != null
                            ? Text(_formatTimestamp(notification['timestamp']))
                            : null,
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_translate(context, 'close')),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildFeatureBox(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 350;
    final isTablet = width >= 600 && width <= 900;
    final isWide = width > 900;

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
          child: Stack(
            children: [
              Column(
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
                      size: isSmallScreen
                          ? 24
                          : (isWide ? 40 : (isTablet ? 40 : 30)),
                      color: color,
                    ),
                  ),
                  SizedBox(height: isWide ? 16 : (isTablet ? 16 : 8)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen
                            ? 14
                            : (isWide ? 18 : (isTablet ? 18 : 16)),
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
              if (badgeCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}