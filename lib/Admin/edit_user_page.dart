// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'admin_sidebar.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> uploadImageUniversalToCloudinary(dynamic image) async {
  const cloudName = 'dgc3hbhva';
  const uploadPreset = 'uploads';
  if (kIsWeb && image is Uint8List) {
    var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', image, filename: 'user_image.png'),
    );
    var response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(respStr);
      return jsonResp['secure_url'];
    } else {
      return null;
    }
  } else if (image is File) {
    final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  } else {
    return null;
  }
}

Future<String?> uploadImageToServer(String filePath) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:3000/upload-image'),
  );
  request.files.add(await http.MultipartFile.fromPath('image', filePath));
  var response = await request.send();
  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final imageUrl = jsonDecode(respStr)['imageUrl'];
    return imageUrl;
  }
  return null;
}

const Map<String, Map<String, String>> adminTranslations = {
  'manage_users': {
    'ar': 'إدارة المستخدمين',
    'en': 'Manage Users',
  },
  'saving_changes': {
    'ar': 'جاري حفظ التعديلات...',
    'en': 'Saving changes...',
  },
  'changes_saved': {
    'ar': 'تم حفظ التعديلات بنجاح',
    'en': 'Changes saved successfully',
  },
  'save_failed': {
    'ar': 'فشل في حفظ التعديلات',
    'en': 'Failed to save changes',
  },
};

Map<String, dynamic> prepareUserDataForUpdate(Map<String, dynamic> data) {
  const validKeys = [
    'FIRST_NAME',
    'FATHER_NAME',
    'GRANDFATHER_NAME',
    'FAMILY_NAME',
    'FULL_NAME',
    'GENDER',
    'BIRTH_DATE',
    'EMAIL',
    'PHONE',
    'ADDRESS',
    'ID_NUMBER',
    'IQRAR',
    'IS_ACTIVE',
    'PERMISSIONS',
    'ROLE',
    'USERNAME',
    'STUDENT_UNIVERSITY_ID',
  ];
  final Map<String, dynamic> filtered = {};
  data.forEach((key, value) {
    if (validKeys.contains(key) && value != null && value.toString().trim().isNotEmpty) {
      filtered[key] = value;
    }
  });
  if (data['IMAGE'] != null && data['IMAGE'].toString().isNotEmpty) {
    filtered['IMAGE'] = data['IMAGE'];
  }
  if (data['ID_IMAGE'] != null && data['ID_IMAGE'].toString().isNotEmpty) {
    filtered['ID_IMAGE'] = data['ID_IMAGE'];
  }
  return filtered;
}

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>>? usersList;
  final String? userName;
  final String? userImageUrl;
  final String Function(BuildContext, String) translate;
  final VoidCallback onLogout;

  const EditUserPage({
    super.key,
    this.user,
    this.usersList,
    this.userName,
    this.userImageUrl,
    required this.translate,
    required this.onLogout,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController firstNameController;
  late TextEditingController fatherNameController;
  late TextEditingController grandfatherNameController;
  late TextEditingController familyNameController;
  late TextEditingController usernameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController idNumberController;
  late TextEditingController permissionsController;
  late TextEditingController studentUniversityIdController;
  DateTime? birthDate;
  String? gender;
  String? role;
  dynamic userImage;
  dynamic idImage;
  bool isIqrar = false;
  String? iqrarBase64;
  bool isSaving = false;
  bool? isActive;
  TextEditingController? declarationController;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoadingUsers = false;
  String? currentUserUid;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    
    firstNameController = TextEditingController();
    fatherNameController = TextEditingController();
    grandfatherNameController = TextEditingController();
    familyNameController = TextEditingController();
    usernameController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
    idNumberController = TextEditingController();
    permissionsController = TextEditingController();
    studentUniversityIdController = TextEditingController();
    declarationController = TextEditingController();
    
    if (widget.user != null && widget.user!['USER_ID'] != null) {
      loadUserForEdit(widget.user!);
    }
    
    fetchAllUsers();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    fatherNameController.dispose();
    grandfatherNameController.dispose();
    familyNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    idNumberController.dispose();
    permissionsController.dispose();
    studentUniversityIdController.dispose();
    declarationController?.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<bool> _checkPermissions() async {
    if (!kIsWeb) {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        await Permission.photos.request();
      }
      return status.isGranted;
    }
    return true;
  }

  // تم إزالة الدالة _pickIqrarImage لأنها غير مستخدمة

  Future<void> _pickImage({bool isIdImage = false}) async {
    try {
      if (!await _checkPermissions()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض صلاحيات الوصول إلى المعرض')),
        );
        return;
      }
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            if (isIdImage) {
              idImage = bytes;
            } else {
              userImage = bytes;
            }
          });
        } else {
          final bytes = await File(image.path).readAsBytes();
          await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 800,
            minHeight: 800,
            quality: 70,
          );
          setState(() {
            if (isIdImage) {
              idImage = File(image.path);
            } else {
              userImage = File(image.path);
            }
          });
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل الصورة: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل الصورة: $e')),
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A7A94),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != birthDate) {
      setState(() => birthDate = picked);
    }
  }

  Future<void> saveUser() async {
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تصحيح الأخطاء في النموذج')),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(widget.translate(context, 'saving_changes')),
          ],
        ),
      ),
    );
    
    setState(() => isSaving = true);
    
    final uid = currentUserUid;
    if (uid == null) {
      setState(() { isSaving = false; });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار مستخدم أولاً')),
        );
      }
      return;
    }

    final String fullName = [
      firstNameController.text.trim(),
      fatherNameController.text.trim(),
      grandfatherNameController.text.trim(),
      familyNameController.text.trim()
    ].where((e) => e.isNotEmpty).join(' ');

    String? imageUrl;
    String? idImageUrl;
    
    if (userImage != null && userImage is! String) {
      imageUrl = await uploadImageUniversalToCloudinary(userImage);
    } else if (userImage is String) {
      imageUrl = userImage;
    }
    
    if (idImage != null && idImage is! String) {
      idImageUrl = await uploadImageUniversalToCloudinary(idImage);
    } else if (idImage is String) {
      idImageUrl = idImage;
    }

    // 🔥 التصحيح هنا - التأكد من أن isActive ليست null
    final bool finalIsActive = isActive ?? false;
    final int isActiveValue = finalIsActive ? 1 : 0;

    final Map<String, dynamic> allData = {
      'FIRST_NAME': firstNameController.text.trim(),
      'FATHER_NAME': fatherNameController.text.trim(),
      'GRANDFATHER_NAME': grandfatherNameController.text.trim(),
      'FAMILY_NAME': familyNameController.text.trim(),
      'FULL_NAME': fullName,
      'USERNAME': usernameController.text.trim(),
      'ID_NUMBER': idNumberController.text.trim(),
      'ROLE': role,
      'PHONE': phoneController.text.trim(),
      'ADDRESS': addressController.text.trim(),
      'IS_ACTIVE': isActiveValue,
      'GENDER': gender,
      if (birthDate != null) 'BIRTH_DATE': birthDate!.toIso8601String(),
      if (imageUrl != null) 'IMAGE': imageUrl,
      if (idImageUrl != null) 'ID_IMAGE': idImageUrl,
      'PERMISSIONS': permissionsController.text.trim(),
      if ((role == 'student' || role == 'dental_student') && studentUniversityIdController.text.isNotEmpty)
        'STUDENT_UNIVERSITY_ID': studentUniversityIdController.text.trim(),
    };

    final Map<String, dynamic> newData = prepareUserDataForUpdate(allData);


    try {
      final updateResponse = await http.put(
        Uri.parse('http://localhost:3000/users/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newData),
      );

      if (updateResponse.statusCode == 200 || updateResponse.statusCode == 204) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final updatedUserData = Map<String, dynamic>.from(newData);
          updatedUserData['USER_ID'] = uid;
          prefs.setString('userData', json.encode(updatedUserData));
        // ignore: empty_catches
        } catch (e) {
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حفظ التعديلات! كود الخطأ: ${updateResponse.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في الاتصال: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> fetchAllUsers() async {
    setState(() => isLoadingUsers = true);
    List<Map<String, dynamic>> users = [];
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/users'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          for (final user in data) {
            if (user is Map<String, dynamic>) {
              users.add(user);
            } else if (user is Map) {
              users.add(Map<String, dynamic>.from(user));
            }
          }
        } else if (data is Map) {
          data.forEach((key, value) {
            final user = Map<String, dynamic>.from(value);
            user['uid'] = key;
            users.add(user);
          });
        }
      }
    // ignore: empty_catches
    } catch (e) {
    }
    setState(() {
      allUsers = users;
      filteredUsers = users;
      isLoadingUsers = false;
    });
  }

  void filterUsers(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        setState(() => filteredUsers = allUsers);
      } else {
        final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        setState(() {
          filteredUsers = allUsers.where((user) {
            final searchableText = [
              user['FIRST_NAME'] ?? '',
              user['FATHER_NAME'] ?? '',
              user['GRANDFATHER_NAME'] ?? '',
              user['FAMILY_NAME'] ?? '',
              user['ID_NUMBER'] ?? '',
              user['USERNAME'] ?? '',
              user['FULL_NAME'] ?? '',
              user['EMAIL'] ?? '',
              user['PHONE'] ?? '',
            ].map((f) => f.toString().toLowerCase().trim()).join(' ');
            
            return words.every((word) => searchableText.contains(word));
          }).toList();
        });
      }
    });
  }

  void loadUserForEdit(Map<String, dynamic> user) {
    
    setState(() {
      firstNameController.text = user['FIRST_NAME']?.toString() ?? '';
      fatherNameController.text = user['FATHER_NAME']?.toString() ?? '';
      grandfatherNameController.text = user['GRANDFATHER_NAME']?.toString() ?? '';
      familyNameController.text = user['FAMILY_NAME']?.toString() ?? '';
      usernameController.text = user['USERNAME']?.toString() ?? '';
      phoneController.text = user['PHONE']?.toString() ?? '';
      addressController.text = user['ADDRESS']?.toString() ?? '';
      idNumberController.text = user['ID_NUMBER']?.toString() ?? '';
      permissionsController.text = user['PERMISSIONS']?.toString() ?? '';
      
      studentUniversityIdController.text = user['STUDENT_UNIVERSITY_ID']?.toString() ?? '';
      
      if (user['BIRTH_DATE'] != null) {
        try {
          birthDate = DateTime.tryParse(user['BIRTH_DATE'].toString());
        } catch (_) {
          birthDate = null;
        }
      } else {
        birthDate = null;
      }
      
      gender = user['GENDER']?.toString();
      role = user['ROLE']?.toString();
      
      // 🔥 التصحيح المحسن مع debugging إضافي
      final activeValue = user['IS_ACTIVE'];
      
      if (activeValue == null) {
        isActive = false;
      } else if (activeValue is bool) {
        isActive = activeValue;
      } else if (activeValue is int) {
        isActive = activeValue == 1;
      } else if (activeValue is String) {
        final strValue = activeValue.toString().trim().toLowerCase();
        isActive = strValue == '1' || strValue == 'true' || strValue == 'نعم' || strValue == 'yes';
      } else {
        isActive = false;
      }
      
      userImage = (user['IMAGE'] != null && user['IMAGE'].toString().startsWith('http'))
          ? user['IMAGE'].toString()
          : null;
      idImage = (user['ID_IMAGE'] != null && user['ID_IMAGE'].toString().startsWith('http'))
          ? user['ID_IMAGE'].toString()
          : null;
      
      declarationController?.text = user['DECLARATION']?.toString() ?? '';
      isIqrar = user['IQRAR'] == true || user['IQRAR'] == 'true';
      
      iqrarBase64 = null;
      if (user['attachments'] != null && user['attachments'] is Map) {
        final attachments = user['attachments'] as Map;
        for (final att in attachments.values) {
          if (att is Map && (att['isIqrar'] == true || att['isIqrar'] == 'true')) {
            if (att['base64'] != null && att['base64'].toString().isNotEmpty) {
              iqrarBase64 = att['base64'].toString();
              break;
            }
          }
        }
      }
      
      currentUserUid = user['USER_ID']?.toString();
      
    });
  }

  Future<void> fetchUserData(String userId) async {
    
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/users/$userId'));
      
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        loadUserForEdit(data);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل في جلب بيانات المستخدم: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في الاتصال: $e')),
        );
      }
    }
  }

  String _translate(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return adminTranslations[key]?[languageProvider.currentLocale.languageCode] ?? key;
  }

  String _getRoleDisplayName(String role) {
    final roleNames = {
      'doctor': 'طبيب',
      'secretary': 'سكرتير',
      'security': 'أمن',
      'admin': 'مدير',
      'dental_student': 'طالب طب أسنان',
      'radiology': 'أشعة',
      'patient': 'مريض',
    };
    return roleNames[role] ?? role;
  }

  Color _getRoleColor(String role) {
    final roleColors = {
      'doctor': Colors.blue,
      'secretary': Colors.green,
      'security': Colors.orange,
      'admin': Colors.red,
      'dental_student': Colors.purple,
      'radiology': Colors.teal,
      'patient': Colors.grey,
    };
    return roleColors[role] ?? Colors.grey;
  }

  Widget buildUserImage(dynamic image) {
    if (image == null || (image is String && image.isEmpty)) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 70, color: Colors.grey),
          SizedBox(height: 8),
          Text('لا توجد صورة', style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    if (image is String && image.startsWith('http')) {
      return Image.network(
        image,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text('تعذر تحميل الصورة من الرابط', style: TextStyle(color: Colors.red, fontSize: 12)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SelectableText(
                image,
                style: const TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('نسخ الرابط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: image));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ رابط الصورة!')),
                );
              },
            ),
          ],
        ),
      );
    }
    if (kIsWeb && image is Uint8List) {
      return Image.memory(
        image,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    }
    if (image is File) {
      return Image.file(
        image,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_circle, size: 70, color: Colors.grey),
        SizedBox(height: 8),
        Text('لا توجد صورة', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    if (_formKey.currentState?.mounted ?? false) {
      final isFormModified = 
          firstNameController.text.isNotEmpty ||
          fatherNameController.text.isNotEmpty ||
          grandfatherNameController.text.isNotEmpty ||
          familyNameController.text.isNotEmpty ||
          usernameController.text.isNotEmpty ||
          phoneController.text.isNotEmpty ||
          addressController.text.isNotEmpty ||
          idNumberController.text.isNotEmpty ||
          studentUniversityIdController.text.isNotEmpty;
        
      if (isFormModified) {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('هل أنت متأكد؟'),
            content: const Text('هناك تغييرات غير محفوظة، هل تريد المغادرة دون الحفظ؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('مغادرة'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A7A94);
    const Color accentColor = Color(0xFF4AB8D8);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Directionality(
        textDirection: languageProvider.isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(widget.translate(context, 'manage_users')),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          drawer: AdminSidebar(
            primaryColor: primaryColor,
            accentColor: accentColor,
            userName: widget.userName,
            userImageUrl: widget.userImageUrl,
            onLogout: widget.onLogout,
            parentContext: context,
            translate: _translate,
            userRole: 'admin',
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'بحث عن مستخدم بالاسم أو رقم الهوية...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: filterUsers,
                    ),
                    if (searchController.text.isNotEmpty)
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(top: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: isLoadingUsers
                              ? const Center(child: CircularProgressIndicator())
                              : filteredUsers.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'لا توجد نتائج',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final fullName = ('${user['FIRST_NAME'] ?? ''} '
                                                         '${user['FATHER_NAME'] ?? ''} '
                                                         '${user['GRANDFATHER_NAME'] ?? ''} '
                                                         '${user['FAMILY_NAME'] ?? ''}').trim();
                                        final username = user['USERNAME'] ?? '';
                                        final role = user['ROLE']?.toString() ?? '';
                                        
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: primaryColor,
                                              child: Text(
                                                fullName.isNotEmpty ? fullName[0] : '?',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            title: Text(
                                              fullName.isNotEmpty ? fullName : (user['FULL_NAME'] ?? ''),
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('@$username'),
                                                Text(
                                                  _getRoleDisplayName(role),
                                                  style: TextStyle(
                                                    color: _getRoleColor(role),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                            onTap: () {
                                              loadUserForEdit(user);
                                              searchController.clear();
                                              setState(() => filteredUsers = allUsers);
                                              FocusScope.of(context).unfocus();
                                            },
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(),
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
                              child: buildUserImage(userImage),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'المعلومات الشخصية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: firstNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'الاسم الأول *',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: fatherNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'اسم الأب *',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: grandfatherNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'اسم الجد *',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: familyNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'اسم العائلة *',
                                        prefixIcon: Icon(Icons.person, color: accentColor),
                                      ),
                                      validator: (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: usernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'اسم المستخدم *',
                                        prefixIcon: Icon(Icons.person_pin, color: accentColor),
                                      ),
                                      validator: (value) {
                                        if (role == 'patient') return null;
                                        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
                                        return null;
                                      },
                                      enabled: role != 'patient',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selectBirthDate,
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'تاريخ الميلاد *',
                                          prefixIcon: const Icon(Icons.calendar_today, color: accentColor),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        child: Text(
                                          birthDate == null
                                              ? 'اختر التاريخ'
                                              : DateFormat('yyyy-MM-dd').format(birthDate!),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: birthDate == null ? Colors.grey[600] : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: gender,
                                    decoration: InputDecoration(
                                      labelText: 'الجنس *',
                                      prefixIcon: const Icon(Icons.wc, color: accentColor),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'male', child: Text('ذكر')),
                                      DropdownMenuItem(value: 'female', child: Text('أنثى')),
                                    ],
                                    onChanged: (value) => setState(() => gender = value),
                                    validator: (value) => value == null ? 'الرجاء اختيار الجنس' : null,
                                  ),
                                  const SizedBox(height: 15),
                                  DropdownButtonFormField<String>(
                                    initialValue: role,
                                    decoration: InputDecoration(
                                      labelText: 'نوع المستخدم *',
                                      prefixIcon: const Icon(Icons.admin_panel_settings, color: accentColor),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'doctor', child: Text('طبيب')),
                                      DropdownMenuItem(value: 'secretary', child: Text('سكرتير')),
                                      DropdownMenuItem(value: 'security', child: Text('أمن')),
                                      DropdownMenuItem(value: 'admin', child: Text('مدير')),
                                      DropdownMenuItem(value: 'dental_student', child: Text('طالب طب أسنان')),
                                      DropdownMenuItem(value: 'radiology', child: Text('أشعة')),
                                      DropdownMenuItem(value: 'patient', child: Text('مريض')),
                                    ],
                                    onChanged: (value) => setState(() => role = value),
                                    validator: (value) => value == null ? 'الرجاء اختيار نوع المستخدم' : null,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف *',
                                  prefixIcon: Icon(Icons.phone, color: accentColor),
                                ),
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
                                  if (value.length < 10) return 'رقم الهاتف يجب أن يكون 10 أرقام';
                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'يجب أن يحتوي على أرقام فقط';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: addressController,
                                decoration: const InputDecoration(
                                  labelText: 'مكان السكن *',
                                  prefixIcon: Icon(Icons.location_on, color: accentColor),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                              ),
                              
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: idNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهوية *',
                                  prefixIcon: Icon(Icons.credit_card, color: accentColor),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 9,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
                                  if (value.length < 9) return 'رقم الهوية يجب أن يكون 9 أرقام';
                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'يجب أن يحتوي على أرقام فقط';
                                  return null;
                                },
                              ),
                              
                              if (role == 'student' || role == 'dental_student') ...[
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: studentUniversityIdController,
                                  decoration: const InputDecoration(
                                    labelText: 'الرقم الجامعي *',
                                    prefixIcon: Icon(Icons.school, color: accentColor),
                                    hintText: 'أدخل الرقم الجامعي للطالب',
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 9,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
                                    if (value.length != 9) return 'الرقم الجامعي يجب أن يكون 9 أرقام بالضبط';
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'يجب أن يحتوي على أرقام فقط';
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'حالة الحساب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive == true ? Icons.check_circle : Icons.cancel,
                                      color: isActive == true ? Colors.green : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'حالة الحساب',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isActive == true ? 'الحساب مفعل' : 'الحساب معطل',
                                            style: TextStyle(
                                              color: isActive == true ? Colors.green : Colors.red,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: isActive ?? false,
                                      activeThumbColor: primaryColor,
                                      activeTrackColor: primaryColor.withOpacity(0.5),
                                      inactiveThumbColor: Colors.red,
                                      inactiveTrackColor: Colors.red.withOpacity(0.5),
                                      onChanged: (val) {
                                        setState(() => isActive = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : saveUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'حفظ التعديلات',
                                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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