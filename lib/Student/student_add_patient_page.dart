// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/language_provider.dart';
import 'student_sidebar.dart';
import 'package:flutter/services.dart';
import 'quick_patient_booking.dart'; 

class StudentAddPatientPage extends StatefulWidget {
  const StudentAddPatientPage({super.key});

  @override
  State<StudentAddPatientPage> createState() => _StudentAddPatientPageState();
}

class _StudentAddPatientPageState extends State<StudentAddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  // تم حذف حقل الإيميل بناءً على طلب المستخدم
  DateTime? _birthDate;
  String? _gender;
  dynamic _patientImage;
  dynamic _idImage;
  bool _isLoading = false;

  // أضف هذه المتغيرات للطالب
  String? _studentName;
  String? _studentImageUrl;

  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchStudentInfo(); // جلب معلومات الطالب
  }

  Future<void> _fetchStudentInfo() async {
    try {
      // استبدل userId بقيمة الطالب الحقيقية إذا توفر
      const userId = 'dummyStudentId';
      final url = Uri.parse('http://localhost:3000/users/$userId');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final firstName = data['firstName'] ?? '';
        final fatherName = data['fatherName'] ?? '';
        final grandfatherName = data['grandfatherName'] ?? '';
        final familyName = data['familyName'] ?? '';
        
        final fullName = [firstName, fatherName, grandfatherName, familyName]
            .where((part) => part.toString().isNotEmpty)
            .join(' ');
            
        setState(() {
          _studentName = fullName.isNotEmpty ? fullName : 'الطالب';
          _studentImageUrl = data['imageUrl'];
        });
      } else {
        setState(() {
          _studentName = 'الطالب';
          _studentImageUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _studentName = 'الطالب';
        _studentImageUrl = null;
      });
    }
  }

  final Map<String, Map<String, String>> _translations = {
    'add_patient_title': {'ar': 'إضافة مريض جديد', 'en': 'Add New Patient'},
    'first_name': {'ar': 'الاسم الأول', 'en': 'First Name'},
    'father_name': {'ar': 'اسم الأب', 'en': 'Father Name'},
    'grandfather_name': {'ar': 'اسم الجد', 'en': 'Grandfather Name'},
    'family_name': {'ar': 'اسم العائلة', 'en': 'Family Name'},
    'id_number': {'ar': 'رقم الهوية', 'en': 'ID Number'},
    'birth_date': {'ar': 'تاريخ الميلاد', 'en': 'Birth Date'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'phone': {'ar': 'رقم الهاتف', 'en': 'Phone Number'},
    'address': {'ar': 'مكان السكن', 'en': 'Address'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'add_patient_button': {'ar': 'إضافة المريض', 'en': 'Add Patient'},
    'add_profile_photo': {'ar': 'إضافة صورة شخصية', 'en': 'Add Profile Photo'},
    'add_id_photo': {'ar': 'إضافة صورة الهوية (إجباري)', 'en': 'Add ID Photo (Required)'},
    'personal_info': {'ar': 'المعلومات الشخصية', 'en': 'Personal Information'},
    'contact_info': {'ar': 'معلومات التواصل', 'en': 'Contact Information'},
    'select_date': {'ar': 'اختر التاريخ', 'en': 'Select date'},
    'validation_required': {
      'ar': 'هذا الحقل مطلوب',
      'en': 'This field is required'
    },
    'validation_id_length': {
      'ar': 'رقم الهوية يجب أن يكون 9 أرقام',
      'en': 'ID must be 9 digits'
    },
    'validation_phone_length': {
      'ar': 'رقم الهاتف يجب أن يكون 10 أرقام',
      'en': 'Phone must be 10 digits'
    },
    'validation_email': {
      'ar': 'البريد الإلكتروني غير صحيح',
      'en': 'Invalid email format'
    },
    'validation_gender': {
      'ar': 'الرجاء اختيار الجنس',
      'en': 'Please select gender'
    },
    'validation_id_image': {
      'ar': 'صورة الهوية مطلوبة',
      'en': 'ID image is required'
    },
    'add_success': {
      'ar': 'تمت إضافة المريض بنجاح',
      'en': 'Patient added successfully'
    },
    'add_error': {
      'ar': 'حدث خطأ أثناء إضافة المريض',
      'en': 'Error adding patient'
    },
    'image_error': {
      'ar': 'حدث خطأ في تحميل الصورة',
      'en': 'Image upload error'
    },
  };

  String _translate(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = languageProvider.isEnglish ? 'en' : 'ar';
    if (_translations.containsKey(key)) {
      final translationsForKey = _translations[key]!;
      if (translationsForKey.containsKey(langCode)) {
        return translationsForKey[langCode]!;
      } else if (translationsForKey.containsKey('en')) {
        return translationsForKey['en']!;
      } else {
        return key;
      }
    } else {
      return key;
    }
  }

  Future<void> _pickImage({required bool isId}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
            if (isId) {
              _idImage = bytes;
            } else {
              _patientImage = bytes;
            }
          });
        } else {
          if (!mounted) return;
          setState(() {
            if (isId) {
              _idImage = File(image.path);
            } else {
              _patientImage = File(image.path);
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('image_error')}: $e')),
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  Future<String?> uploadImageUniversalToCloudinary(dynamic image) async {
    const cloudName = 'dgc3hbhva';
    const uploadPreset = 'uploads';
    if (image == null) return null;
    try {
      if (kIsWeb && image is Uint8List) {
        var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(
          http.MultipartFile.fromBytes('file', image, filename: 'patient_image.png'),
        );
        var response = await request.send();
        final respStr = await response.stream.bytesToString();
        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(respStr);
          return jsonResp['secure_url'];
        }
        return null;
      } else if (image is File) {
        final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );
        var response = await request.send();
        final respStr = await response.stream.bytesToString();
        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(respStr);
          return jsonResp['secure_url'];
        }
        return null;
      }
      return null;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('image_error')}: $e')),
      );
      return null;
    }
  }

  Future<void> _addPatient() async {
    if (_isLoading) return; // Prevent double tap
    setState(() => _isLoading = true);
    try {
      if (!_formKey.currentState!.validate()) {
        setState(() => _isLoading = false);
        return;
      }
      if (_gender == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('validation_gender'))),
        );
        setState(() => _isLoading = false);
        return;
      }
      if (_idImage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('validation_id_image'))),
        );
        setState(() => _isLoading = false);
        return;
      }

      final idNumber = _idNumberController.text.trim();
      // تحقق من رقم الهوية عبر API
      final checkUrl = Uri.parse('http://localhost:3000/patients/check-id');
      final checkResponse = await http.post(checkUrl, body: json.encode({'idNumber': idNumber}), headers: {'Content-Type': 'application/json'});
      debugPrint('DEBUG: Response status: ${checkResponse.statusCode}');
      debugPrint('DEBUG: Response body: ${checkResponse.body}');
      if (checkResponse.statusCode == 409) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الهوية مسجل مسبقاً أو الحساب مفعل من قبل')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Check if ID exists in pending users
      final pendingCheckUrl = Uri.parse('http://localhost:3000/pendingUsers/check-id');
      final pendingCheckResponse = await http.post(pendingCheckUrl, body: json.encode({'idNumber': idNumber}), headers: {'Content-Type': 'application/json'});
      debugPrint('DEBUG: Pending check response status: ${pendingCheckResponse.statusCode}');
      debugPrint('DEBUG: Pending check response body: ${pendingCheckResponse.body}');
      if (pendingCheckResponse.statusCode == 409) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الهوية موجود بالفعل في قائمة المعلقين')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // جلب معرف الطالب الحالي (المستخدم المسجل دخول
      // ignore: use_build_context_synchronously
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      String? studentId = languageProvider.currentUserId;
      debugPrint('DEBUG: provider.currentUserId = ${languageProvider.currentUserId}');
      if (studentId == null || studentId.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          // Try USER_ID key first
          studentId = prefs.getString('USER_ID');
          if (studentId == null) {
            // Try parsing stored userData JSON
            final userDataStr = prefs.getString('userData');
            if (userDataStr != null) {
              final userData = json.decode(userDataStr);
              if (userData is Map && userData['USER_ID'] != null) {
                studentId = userData['USER_ID'].toString();
              }
            }
          }
          // If found, update provider for future usage
          if (studentId != null && studentId.isNotEmpty) {
            try {
              languageProvider.setUserId(studentId);
            } catch (_) {}
          }
        } catch (_) {
          // ignore errors and continue with null studentId
        }
      }
      debugPrint('DEBUG: resolved studentId = $studentId');
      if (studentId == null || studentId.isEmpty || studentId == 'unknown_student_id') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('DEBUG: studentId is null/unknown: $studentId')),
          );
        }
      }

      // generate a random UID for the patient (not a real Firebase Auth user)
      final String patientUid = const Uuid().v4();
      String? imageUrl = await uploadImageUniversalToCloudinary(_patientImage);
      String? idImageUrl = await uploadImageUniversalToCloudinary(_idImage);
      final patientData = {
        'firstName': _firstNameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'grandfatherName': _grandfatherNameController.text.trim(),
        'familyName': _familyNameController.text.trim(),
        'idNumber': idNumber,
        'birthDate': _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null,
        'gender': _gender,
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'image': imageUrl,
        'idImage': idImageUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
        'role': 'patient',
        'authUid': patientUid,
      };
      final addUrl = Uri.parse('http://localhost:3000/pendingUsers');
      final addResponse = await http.post(addUrl, body: json.encode({'uid': patientUid, ...patientData}), headers: {'Content-Type': 'application/json'});
      if (addResponse.statusCode != 200 && addResponse.statusCode != 201) {
        throw Exception('API error: ${addResponse.body}');
      }

      // إرسال إشعار للسكرتير عبر API (اختياري)
      try {
        final notifyUrl = Uri.parse('http://localhost:3000/notify-secretary');
        await http.post(notifyUrl, body: json.encode({
          'title': _translate('add_patient_title'),
          'message': '${patientData['firstName']} ${patientData['familyName']} - ${patientData['idNumber']}',
          'userId': patientUid,
          'userData': patientData,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
          'type': 'new_patient',
        }), headers: {'Content-Type': 'application/json'});
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('add_success'))),
      );
      _formKey.currentState!.reset();
      setState(() {
        _patientImage = null;
        _idImage = null;
        _birthDate = null;
        _gender = null;
      });
      // Navigate to quick booking page for new patient
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              PrimaryExamBookingPage(
                patientUid: patientUid,
                patientName: [
                  _firstNameController.text.trim(),
                  _fatherNameController.text.trim(),
                  _grandfatherNameController.text.trim(),
                  _familyNameController.text.trim(),
                ].where((e) => e.isNotEmpty).join(' '),
                patientIdNumber: idNumber,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('add_error')}: $e')),
      );
      setState(() => _isLoading = false);
    }
    // Don't set _isLoading to false here, because we either navigated or already set it on error/validation
  }

  Widget _buildImageWidget({required bool isId}) {
    final image = isId ? _idImage : _patientImage;
    if (image == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            isId ? _translate('add_id_photo') : _translate('add_profile_photo'),
            style: TextStyle(color: primaryColor),
          ),
        ],
      );
    }
    return kIsWeb
        ? Image.memory(image as Uint8List, width: 150, height: 150, fit: BoxFit.cover)
        : Image.file(image as File, width: 150, height: 150, fit: BoxFit.cover);
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: primaryColor.withAlpha(204)),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderRadioButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _translate('gender'),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(_translate('male')),
                value: 'male',
                groupValue: _gender,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(_translate('female')),
                value: 'female',
                groupValue: _gender,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Directionality(
      textDirection: languageProvider.isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove the back arrow
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(_translate('add_patient_title')),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                languageProvider.toggleLanguage();
              },
            ),
          ],
        ),
        drawer: StudentSidebar(
          allowedFeatures: const <String>[
            'view_examinations',
            'add_patient',
            'upload_xray',
            'my_appointments',
          ],
          studentName: _studentName,
          studentImageUrl: _studentImageUrl,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final double horizontalPadding = isWide ? constraints.maxWidth * 0.15 : 16;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Images Row
                    isWide
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _pickImage(isId: false),
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: primaryColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildImageWidget(isId: false),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _pickImage(isId: true),
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _buildImageWidget(isId: true),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              GestureDetector(
                                onTap: () => _pickImage(isId: false),
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: primaryColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildImageWidget(isId: false),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => _pickImage(isId: true),
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildImageWidget(isId: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 30),
                    // Personal Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _translate('personal_info'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          (isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _firstNameController,
                                          labelText: _translate('first_name'),
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _fatherNameController,
                                          labelText: _translate('father_name'),
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _grandfatherNameController,
                                          labelText: _translate('grandfather_name'),
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _familyNameController,
                                          labelText: _translate('family_name'),
                                          prefixIcon: Icon(Icons.person, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _firstNameController,
                                        labelText: _translate('first_name'),
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required');
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _fatherNameController,
                                        labelText: _translate('father_name'),
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required');
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _grandfatherNameController,
                                        labelText: _translate('grandfather_name'),
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required');
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _familyNameController,
                                        labelText: _translate('family_name'),
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required');
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                )),
                          const SizedBox(height: 15),
                          (isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _idNumberController,
                                          labelText: _translate('id_number'),
                                          keyboardType: TextInputType.number,
                                          maxLength: 9,
                                          prefixIcon: Icon(Icons.credit_card, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required');
                                            }
                                            if (value.length < 9) {
                                              return _translate('validation_id_length');
                                            }
                                            return null;
                                          },
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: InkWell(
                                          onTap: _selectBirthDate,
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: _translate('birth_date'),
                                              labelStyle: TextStyle(color: primaryColor.withAlpha(204)),
                                              prefixIcon: Icon(Icons.calendar_today, color: accentColor),
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                            ),
                                            child: Text(
                                              _birthDate == null
                                                  ? _translate('select_date')
                                                  : DateFormat('yyyy-MM-dd').format(_birthDate!),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: _birthDate == null ? Colors.grey[600] : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _idNumberController,
                                        labelText: _translate('id_number'),
                                        keyboardType: TextInputType.number,
                                        maxLength: 9,
                                        prefixIcon: Icon(Icons.credit_card, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required');
                                          }
                                          if (value.length < 9) {
                                            return _translate('validation_id_length');
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: InkWell(
                                        onTap: _selectBirthDate,
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: _translate('birth_date'),
                                            labelStyle: TextStyle(color: primaryColor.withAlpha(204)),
                                            prefixIcon: Icon(Icons.calendar_today, color: accentColor),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                          ),
                                          child: Text(
                                            _birthDate == null
                                                ? _translate('select_date')
                                                : DateFormat('yyyy-MM-dd').format(_birthDate!),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _birthDate == null ? Colors.grey[600] : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                          const SizedBox(height: 15),
                          _buildGenderRadioButtons(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Contact Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _translate('contact_info'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _phoneController,
                                          labelText: _translate('phone'),
                                          keyboardType: TextInputType.phone,
                                          maxLength: 10,
                                          prefixIcon: Icon(Icons.phone, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required');
                                            }
                                            if (value.length < 10) {
                                              return _translate('validation_phone_length');
                                            }
                                            return null;
                                          },
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildTextFormField(
                                          controller: _addressController,
                                          labelText: _translate('address'),
                                          prefixIcon: Icon(Icons.location_on, color: accentColor),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return _translate('validation_required');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _phoneController,
                                        labelText: _translate('phone'),
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        prefixIcon: Icon(Icons.phone, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required');
                                          }
                                          if (value.length < 10) {
                                            return _translate('validation_phone_length');
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 60,
                                      child: _buildTextFormField(
                                        controller: _addressController,
                                        labelText: _translate('address'),
                                        prefixIcon: Icon(Icons.location_on, color: accentColor),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return _translate('validation_required');
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _translate('add_patient_button'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _familyNameController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}