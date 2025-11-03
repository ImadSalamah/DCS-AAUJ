// ignore_for_file: empty_catches, use_build_context_synchronously, deprecated_member_use, unnecessary_type_check

import 'package:flutter/material.dart';
import "../Secretry/secretary_sidebar.dart" as secretary;
import '../Admin/admin_sidebar.dart' as admin;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

// 🔥 دالة لعرض الإقرار في دايالوج
void _showIqrarDialog(BuildContext context, String imageUrl, String patientName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إقرار المريض: $patientName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'تعذر تحميل الصورة',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ الإقرار')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A7A94),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// 🔥 دالة جديدة لعرض وإعداد حدود الحجوزات للسنوات الرابعة والخامسة
void showBookingLimitsDialog(BuildContext context) async {
  final TextEditingController fourthYearController = TextEditingController();
  final TextEditingController fifthYearController = TextEditingController();
  bool loading = false;

  // جلب الإعدادات الحالية
  try {
    final response = await http.get(Uri.parse('http://localhost:3000/bookingSettings'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      fourthYearController.text = data['fourthYearLimit']?.toString() ?? '2';
      fifthYearController.text = data['fifthYearLimit']?.toString() ?? '3';
    }
  } catch (e) {
    fourthYearController.text = '2';
    fifthYearController.text = '3';
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('حدود الحجوزات اليومية', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // إعدادات السنة الرابعة
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, color: Color(0xFF2A7A94), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'طلاب السنة الرابعة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2A7A94),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: fourthYearController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'الحد الأقصى للحجوزات اليومية',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.light),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // إعدادات السنة الخامسة
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, color: Color(0xFF00B4D8), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'طلاب السنة الخامسة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00B4D8),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: fifthYearController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'الحد الأقصى للحجوزات اليومية',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.light),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // معلومات إضافية
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 معلومات:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A7A94),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'هذه الإعدادات تحدد الحد الأقصى لعدد الحجوزات التي يمكن لكل طالب القيام بها في اليوم الواحد',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  final fourthYearLimit = int.tryParse(fourthYearController.text);
                  final fifthYearLimit = int.tryParse(fifthYearController.text);

                  if (fourthYearLimit == null || fifthYearLimit == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('يرجى إدخال أرقام صحيحة'))
                    );
                    return;
                  }

                  if (fourthYearLimit <= 0 || fifthYearLimit <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('يجب أن يكون العدد أكبر من الصفر'))
                    );
                    return;
                  }

                  setState(() {
                    loading = true;
                  });

                  try {
                    final response = await http.put(
                      Uri.parse('http://localhost:3000/bookingSettings'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'fourthYearLimit': fourthYearLimit,
                        'fifthYearLimit': fifthYearLimit,
                      }),
                    );
                    
                    if (response.statusCode == 200) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ إعدادات حدود الحجوزات بنجاح.'))
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('فشل في حفظ الإعدادات.'))
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('حدث خطأ أثناء حفظ الإعدادات.'))
                    );
                  } finally {
                    setState(() {
                      loading = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A7A94),
                  foregroundColor: Colors.white,
                ),
                child: loading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('حفظ', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        }
      );
    },
  );
}

class BookingSettingsPage extends StatefulWidget {
  const BookingSettingsPage({super.key});

  @override
  State<BookingSettingsPage> createState() => _BookingSettingsPageState();
}

class _BookingSettingsPageState extends State<BookingSettingsPage> {
  String translate(BuildContext context, String key) => key;
  String _searchText = '';
  String? userType;
  String? userName;
  String? userImageUrl;
  String? userRoleFromApi; // 🔥 تخزين الـ role من API
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> waitingList = [];
  Set<String> _pendingPatientIds = <String>{};
  bool _loading = true;
  bool _accessDenied = false;
  DateTime selectedDate = DateTime.now();
  
  final Map<String, Map<String, dynamic>> _patientInfoCache = {};

  @override
  void initState() {
    super.initState();
    _checkUserAccess();
  }

  // 🔥 جلب بيانات المستخدم من API مباشرة
  Future<Map<String, dynamic>?> _fetchUserDataFromApi(String userId) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/users/$userId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
    }
    return null;
  }

  // 🔥 التحقق من صلاحية المستخدم مع الاعتماد على API مباشرة
  Future<void> _checkUserAccess() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final userId = languageProvider.currentUserId;


    if (userId == null) {
      setState(() {
        _accessDenied = true;
        _loading = false;
      });
      return;
    }

    // 🔥 جلب بيانات المستخدم مباشرة من API
    final userData = await _fetchUserDataFromApi(userId);
    
    if (userData == null) {
      setState(() {
        _accessDenied = true;
        _loading = false;
      });
      return;
    }

    final roleString = userData['ROLE']?.toString();
    final userNameFromApi = userData['FULL_NAME']?.toString();
    final userImageFromApi = userData['IMAGE']?.toString();


    if (roleString == null) {
      setState(() {
        _accessDenied = true;
        _loading = false;
      });
      return;
    }

    // 🔥 التحقق من الصلاحية - السماح فقط للأدمن والسكرتير
    if (roleString != 'admin' && roleString != 'secretary') {
      setState(() {
        _accessDenied = true;
        _loading = false;
      });
      return;
    }

    
    // 🔥 تعيين بيانات المستخدم
    setState(() {
      userType = roleString; // استخدام الـ role مباشرة من API
      userRoleFromApi = roleString;
      userName = userNameFromApi ?? 'المستخدم';
      userImageUrl = userImageFromApi;
      _loading = false;
    });


    // 🔥 جلب البيانات بعد التأكد من الصلاحية
    _fetchAll();
  }

  Widget? _buildSidebar(BuildContext context) {
    if (userType == 'secretary') {
      return secretary.SecretarySidebar(
        primaryColor: const Color(0xFF2A7A94),
        accentColor: const Color(0xFF00B4D8),
        parentContext: context,
        translate: translate,
        userName: userName,
        userImageUrl: userImageUrl, 
        userRole: 'secretary',
      );
    } else if (userType == 'admin') {
      return admin.AdminSidebar(
        primaryColor: const Color(0xFF2A7A94),
        accentColor: const Color(0xFF00B4D8),
        parentContext: context,
        translate: translate,
        userName: userName,
        userImageUrl: userImageUrl,
        userRole: 'admin',
      );
    }
    return null;
  }

  Future<void> _fetchAll() async {
    if (_accessDenied) return;
    
    setState(() {
      _loading = true;
    });
    await Future.wait([
      _fetchBookings(),
      _fetchWaitingList(),
      _fetchPendingPatientIds(),
    ]);
    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchPendingPatientIds() async {
    final Set<String> ids = <String>{};
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/pendingUsers'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          for (final patient in data) {
            if (patient['USER_UID'] != null) {
              ids.add(patient['USER_UID'].toString());
            }
          }
        }
      }
    } catch (e) {}
    setState(() {
      _pendingPatientIds = ids;
    });
  }

  Future<void> _fetchWaitingList() async {
    final List<Map<String, dynamic>> loaded = [];
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/waitingList'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          for (final item in data) {
            loaded.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (e) {}
    setState(() {
      waitingList = loaded;
    });
  }

  Future<void> _fetchBookings() async {
    final List<Map<String, dynamic>> loaded = [];
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/appointments'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          for (final booking in data) {
            final bookingMap = Map<String, dynamic>.from(booking);
            
            final appointmentDate = booking['APPOINTMENT_DATE']?.toString() ?? '';
            if (appointmentDate.isNotEmpty) {
              try {
                final localDate = DateTime.parse(appointmentDate).toLocal();
                bookingMap['DISPLAY_DATE'] = "${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}";
              } catch (e) {
                bookingMap['DISPLAY_DATE'] = appointmentDate.split('T').first;
              }
            }
            
            loaded.add(bookingMap);
          }
        }
      }
    } catch (e) {}
    setState(() {
      bookings = loaded;
    });
  }

  Future<Map<String, dynamic>> _getStudentInfo(String studentId) async {
    try {
      final studentResponse = await http.get(Uri.parse('http://localhost:3000/students/$studentId'));
      if (studentResponse.statusCode == 200) {
        final studentData = json.decode(studentResponse.body);
        final universityId = studentData['STUDENT_UNIVERSITY_ID']?.toString() ?? '';

        final userResponse = await http.get(Uri.parse('http://localhost:3000/users/$studentId'));
        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          return {
            'name': userData['FULL_NAME']?.toString() ?? '',
            'universityId': universityId,
          };
        }
      }
    } catch (e) {}
    return {'name': '', 'universityId': ''};
  }

  bool _isValidIqrarLink(String link) {
    if (link.isEmpty) return false;
    
    final invalidPatterns = [
      'https://example.com',
      'default-iqrar.png',
      'placeholder',
      'null',
      'undefined'
    ];
    
    for (final pattern in invalidPatterns) {
      if (link.toLowerCase().contains(pattern)) {
        return false;
      }
    }
    
    final hasValidLength = link.length > 10;
    final hasImageExtension = link.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp|pdf|svg)'));
    final hasHttpProtocol = link.toLowerCase().startsWith('http');
    
    return hasValidLength && hasImageExtension && hasHttpProtocol;
  }

  Future<Map<String, dynamic>> _getPatientInfo(String patientId) async {
    if (_patientInfoCache.containsKey(patientId)) {
      return _patientInfoCache[patientId]!;
    }
    
    Map<String, dynamic> result = {
      'firstName': '', 
      'familyName': '', 
      'phone': '', 
      'birthDate': '', 
      'iqrar': '',
      'hasValidIqrar': false,
      'source': 'NONE',
      'fullName': '',
    };

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/patients/by-appointment-id/$patientId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final iqrar = data['IQRAR']?.toString().trim() ?? '';
        final hasValidIqrar = _isValidIqrarLink(iqrar);
        final firstName = data['FIRSTNAME']?.toString() ?? '';
        final familyName = data['FAMILYNAME']?.toString() ?? '';
        
        result = {
          'firstName': firstName,
          'familyName': familyName,
          'phone': data['PHONE']?.toString() ?? '',
          'birthDate': data['BIRTHDATE']?.toString() ?? '',
          'iqrar': iqrar,
          'hasValidIqrar': hasValidIqrar,
          'source': 'PATIENTS_BY_IDNUMBER',
          'patientUid': data['PATIENT_UID']?.toString() ?? '',
          'fullName': '$firstName $familyName'.trim(),
        };
      }
    } catch (e) {}
    
    if (result['phone']?.isEmpty == true) {
      try {
        final response = await http.get(Uri.parse('http://localhost:3000/patients/$patientId'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final iqrar = data['IQRAR']?.toString().trim() ?? '';
          final hasValidIqrar = _isValidIqrarLink(iqrar);
          final firstName = data['FIRSTNAME']?.toString() ?? '';
          final familyName = data['FAMILYNAME']?.toString() ?? '';
          
          result = {
            'firstName': firstName,
            'familyName': familyName,
            'phone': data['PHONE']?.toString() ?? '',
            'birthDate': data['BIRTHDATE']?.toString() ?? '',
            'iqrar': iqrar,
            'hasValidIqrar': hasValidIqrar,
            'source': 'PATIENTS',
            'fullName': '$firstName $familyName'.trim(),
          };
        }
      } catch (e) {}
    }
    
    if (result['phone']?.isEmpty == true) {
      try {
        final response = await http.get(Uri.parse('http://localhost:3000/pendingUsers'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List) {
            final pendingPatient = data.firstWhere(
              (user) => user['USER_UID']?.toString() == patientId || user['IDNUMBER']?.toString() == patientId,
              orElse: () => {},
            );
            
            if (pendingPatient.isNotEmpty) {
              final iqrar = pendingPatient['IQRAR']?.toString().trim() ?? '';
              final hasValidIqrar = _isValidIqrarLink(iqrar);
              final firstName = pendingPatient['FIRSTNAME']?.toString() ?? '';
              final familyName = pendingPatient['FAMILYNAME']?.toString() ?? '';
              
              result = {
                'firstName': firstName,
                'familyName': familyName,
                'phone': pendingPatient['PHONE']?.toString() ?? '',
                'birthDate': pendingPatient['BIRTHDATE']?.toString() ?? '',
                'iqrar': iqrar,
                'hasValidIqrar': hasValidIqrar,
                'source': 'PENDINGUSERS',
                'fullName': '$firstName $familyName'.trim(),
              };
            }
          }
        }
      } catch (e) {}
    }
    
    _patientInfoCache[patientId] = result;
    return result;
  }

  Future<void> _addToWaitingList(BuildContext context, String patientId, String patientName, String day, Map<String, dynamic> patientInfo) async {
    if (patientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد اسم للمريض!')),
      );
      return;
    }

    final newEntry = {
      'PATIENT_UID': patientId,
      'PATIENT_NAME': patientName,
      'APPOINTMENT_DATE': day,
      'STATUS': 'WAITING',
      'PHONE': patientInfo['phone'] ?? '',
      'FIRSTNAME': patientInfo['firstName'] ?? '',
      'FAMILYNAME': patientInfo['familyName'] ?? '',
      'FULL_NAME': patientInfo['fullName'] ?? '',
      'BIRTHDATE': patientInfo['birthDate'] ?? '',
      'IQRAR': patientInfo['iqrar'] ?? '',
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/waitingList'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newEntry),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchWaitingList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المريض إلى قائمة الانتظار')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في إضافة المريض إلى قائمة الانتظار')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الإضافة')),
      );
    }
  }

  int _getStudentYear(String universityId) {
    if (universityId.length >= 4) {
      final startYear = int.tryParse(universityId.substring(0, 4));
      if (startYear != null) {
        final now = DateTime.now();
        int year = now.year - startYear + 1;
        if (now.month < 11) {
          year -= 1;
        }
        return year > 0 ? year : 1;
      }
    }
    return 0;
  }

  bool _flexibleNameMatch(String name1, String name2) {
    if (name1.trim() == name2.trim()) return true;
    
    final words1 = name1.trim().split(' ').where((word) => word.isNotEmpty).toList();
    final words2 = name2.trim().split(' ').where((word) => word.isNotEmpty).toList();
    
    final uniqueWords1 = words1.toSet().toList();
    final uniqueWords2 = words2.toSet().toList();
    
    if (uniqueWords1.join(' ') == uniqueWords2.join(' ')) return true;
    
    if (words1.isNotEmpty && words2.isNotEmpty) {
      final firstWord1 = words1.first;
      final firstWord2 = words2.first;
      final lastWord1 = words1.last;
      final lastWord2 = words2.last;
      
      if (firstWord1 == firstWord2 && lastWord1 == lastWord2) return true;
    }
    
    for (final word1 in words1) {
      for (final word2 in words2) {
        if (word1 == word2 && word1.length > 2) {
          return true;
        }
      }
    }
    
    return false;
  }

  Future<bool> _checkExamStatus(String patientName, String appointmentDate) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/all-examinations-full')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> exams = json.decode(response.body);
        
        final String formattedAppointmentDate = appointmentDate.split('T').first;
        
        
        for (final exam in exams) {
          final examDate = exam['EXAM_DATE']?.toString() ?? '';
          final patientData = exam['PATIENT_DATA'] ?? {};
          final examPatientFirstName = patientData['FIRSTNAME']?.toString() ?? '';
          final examPatientFamilyName = patientData['FAMILYNAME']?.toString() ?? '';
          final examPatientName = '$examPatientFirstName $examPatientFamilyName'.trim();
          
          String formattedExamDate = examDate.split(' ').first;
          
          final namesMatch = _flexibleNameMatch(patientName, examPatientName);
          final datesMatch = formattedExamDate == formattedAppointmentDate;
          
          
          if (namesMatch && datesMatch) {
            return true;
          }
        }
        
      } else {
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Widget _buildIqrarStatusWidget(String patientId, String patientName) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getPatientInfo(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2)
          );
        }
        
        final patientInfo = snapshot.data ?? {};
        final hasValidIqrar = patientInfo['hasValidIqrar'] == true;
        final iqrarLink = patientInfo['iqrar'] ?? '';
        
        return SizedBox(
          width: 80,
          height: 40,
          child: hasValidIqrar 
              ? ElevatedButton(
                  onPressed: () {
                    _showIqrarDialog(context, iqrarLink, patientName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'عرض الإقرار',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'لم يرفع',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A7A94),
          title: const Text('رفض الوصول', style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'غير مسموح لك بالوصول إلى هذه الصفحة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'يجب أن تكون أدمن أو سكرتير للوصول إلى إعدادات الحجوزات',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const Color primaryColor = Color(0xFF2A7A94);
    const Color accentColor = Color(0xFF00B4D8);
    const Color backgroundColor = Color(0xFFF6F8FA);

    final filteredBookings = bookings.where((b) {
      final dateStr = b['APPOINTMENT_DATE']?.toString() ?? '';
      
      DateTime? appointmentDate;
      try {
        appointmentDate = DateTime.parse(dateStr).toLocal();
      } catch (e) {
        appointmentDate = null;
      }
      
      final bool isSameDate = appointmentDate != null &&
          appointmentDate.year == selectedDate.year &&
          appointmentDate.month == selectedDate.month &&
          appointmentDate.day == selectedDate.day;
      
      if (!isSameDate) return false;
      if (_searchText.trim().isEmpty) return true;
      final patientName = (b['PATIENT_NAME']?.toString() ?? '').toLowerCase();
      return patientName.contains(_searchText.trim().toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'جدول الحجوزات - ${userType == 'admin' ? 'أدمن' : 'سكرتير'}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        // 🔥 إضافة زر حدود الحجوزات فقط للأدمن
        actions: [
          if (userType == 'admin') // فقط للأدمن
            IconButton(
              icon: const Icon(Icons.light, size: 24),
              tooltip: 'حدود الحجوزات للطلاب',
              onPressed: () {
                showBookingLimitsDialog(context);
              },
            ),
        ],
      ),
      drawer: _buildSidebar(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Text('اليوم:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text(
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'بحث باسم المريض...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchText = val;
                            });
                          },
                        ),
                      ),
                      // 🔥 زر إضافي لحدود الحجوزات بجانب البحث - فقط للأدمن
                      const SizedBox(width: 8),
                      if (userType == 'admin') // فقط للأدمن
                        Tooltip(
                          message: 'حدود الحجوزات',
                          child: IconButton(
                            icon: const Icon(Icons.light, color: Color(0xFF2A7A94)),
                            onPressed: () => showBookingLimitsDialog(context),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredBookings.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد حجوزات في هذا اليوم',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : _buildBookingsTable(filteredBookings),
                ),
              ],
            ),
    );
  }

  Widget _buildBookingsTable(List<Map<String, dynamic>> filteredBookings) {
    return FutureBuilder(
      future: Future.wait([
        Future.wait(filteredBookings.map((b) => _getPatientInfo(b['PATIENT_ID_NUMBER'] ?? '')).toList()),
        Future.wait(filteredBookings.map((b) => _getStudentInfo(b['STUDENT_ID'] ?? '')).toList()),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final patientInfos = (snapshot.data![0] is List) ? snapshot.data![0] : <Map<String, dynamic>>[];
        final studentInfos = (snapshot.data![1] is List) ? snapshot.data![1] : <Map<String, dynamic>>[];
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder.all(color: Colors.grey, width: 1),
            headingRowColor: WidgetStateProperty.all(const Color(0xFF005DAA).withOpacity(0.9)),
            dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF00B4D8).withOpacity(0.2);
              }
              return null;
            }),
            columns: const [
              DataColumn(label: Text('الرقم التسلسلي', style: TextStyle(color: Colors.white, fontSize: 14))),
              DataColumn(label: Text('اسم الطالب', style: TextStyle(color: Colors.white, fontSize: 14))),
              DataColumn(label: Text('سنة الطالب', style: TextStyle(color: Colors.white, fontSize: 14))),
              DataColumn(label: Text('اسم المريض', style: TextStyle(color: Colors.white, fontSize: 14))),
              DataColumn(label: Text('اليوم', style: TextStyle(color: Colors.white, fontSize: 14))),
              DataColumn(label: Text('إقرار', style: TextStyle(color: Colors.white, fontSize: 14))),
              DataColumn(label: Text('إضافة لقائمة الانتظار', style: TextStyle(color: Colors.white, fontSize: 14))),
              DataColumn(label: Text('حالة الفحص', style: TextStyle(color: Colors.white, fontSize: 14))),
            ],
            rows: List.generate(filteredBookings.length, (i) {
              final booking = filteredBookings[i];
              final patientInfo = (patientInfos.length > i) ? patientInfos[i] : {'source': 'NONE'};
              final studentInfo = (studentInfos.length > i) ? studentInfos[i] : {'name': '', 'universityId': ''};
              
              final studentName = studentInfo['name'] ?? '';
              final universityId = studentInfo['universityId'] ?? '';
              final year = _getStudentYear(universityId);

              final patientId = booking['PATIENT_ID_NUMBER']?.toString() ?? '';
              final day = booking['DISPLAY_DATE'] ?? booking['APPOINTMENT_DATE']?.toString().split('T').first ?? '';
              
              final serial = (i + 1).toString();
              
              final patientName = booking['PATIENT_NAME']?.toString() ?? '';
              final patientSource = patientInfo['source'] ?? 'NONE';

              final isPending = _pendingPatientIds.contains(patientId);
              final isFromPendingUsers = patientSource == 'PENDINGUSERS';
              
              Color? rowColor;
              if (isPending) {
                rowColor = Colors.red.withOpacity(0.3);
              } else if (isFromPendingUsers) {
                rowColor = Colors.orange.withOpacity(0.2);
              }

              Widget iqrarStatusWidget = _buildIqrarStatusWidget(patientId, patientName);

              final waitingEntry = waitingList.firstWhere(
                (w) => (w['PATIENT_NAME'] == patientName && w['APPOINTMENT_DATE']?.toString().split('T').first == day),
                orElse: () => {},
              );
              
              Widget addToWaitingListButton;

              if (waitingEntry.isNotEmpty && waitingEntry['WAITING_ID'] != null) {
                addToWaitingListButton = ElevatedButton.icon(
                  icon: const Icon(Icons.remove_circle, color: Colors.white, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () async {
                    try {
                      await http.delete(Uri.parse('http://localhost:3000/waitingList/${waitingEntry['WAITING_ID']}'));
                      await _fetchWaitingList();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إزالة المريض من قائمة الانتظار')),
                      );
                    } catch (e) {}
                  },
                  label: const Text('إزالة', style: TextStyle(color: Colors.white, fontSize: 12)),
                );
              } else {
                final disableAddBtn = isPending || isFromPendingUsers || !patientInfo['hasValidIqrar'];
                
                addToWaitingListButton = ElevatedButton(
                  onPressed: disableAddBtn ? null : () async {
                    await _addToWaitingList(context, patientId, patientName, day, patientInfo);
                  },
                  style: disableAddBtn
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        )
                      : ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4D8), 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                  child: Text(
                    isFromPendingUsers ? 'غير مسموح' : 'إضافة',
                    style: TextStyle(
                      color: disableAddBtn ? Colors.white : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              Widget examStatusWidget = FutureBuilder<bool>(
                future: _checkExamStatus(patientName, day),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return const Tooltip(
                      message: 'خطأ في التحقق من حالة الفحص',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text('خطأ', style: TextStyle(fontSize: 10, color: Colors.orange)),
                        ],
                      ),
                    );
                  }
                  
                  final done = snapshot.data == true;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: done ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: done ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      done ? 'تم الفحص ✅' : 'لم يتم ❌',
                      style: TextStyle(
                        color: done ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              );

              return DataRow(
                color: rowColor != null ? WidgetStateProperty.all(rowColor) : null,
                cells: [
                  DataCell(Text(serial, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(studentName, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(year > 0 ? year.toString() : 'غير متوفر', style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Text(
                      patientName,
                      style: TextStyle(
                        fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
                        color: isPending ? Colors.red : (isFromPendingUsers ? Colors.orange : Colors.black),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataCell(Text(day, style: const TextStyle(fontSize: 12))),
                  DataCell(Center(child: iqrarStatusWidget)),
                  DataCell(Center(child: addToWaitingListButton)),
                  DataCell(Center(child: examStatusWidget)),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}