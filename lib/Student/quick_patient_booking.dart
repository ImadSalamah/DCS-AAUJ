// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class PrimaryExamBookingPage extends StatefulWidget {
  final String patientUid;
  final String patientName;
  final String patientIdNumber;
  const PrimaryExamBookingPage({
    super.key,
    required this.patientUid,
    required this.patientName,
    required this.patientIdNumber,
  });

  @override
  State<PrimaryExamBookingPage> createState() => _PrimaryExamBookingPageState();
}

class _PrimaryExamBookingPageState extends State<PrimaryExamBookingPage> {
  DateTime? selectedDate;
  bool isLoading = false;
  bool declarationUploaded = false;
  String? declarationImageUrl;
  dynamic declarationImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() { selectedDate = picked; });
    }
  }

  Future<String?> uploadImageToCloudinary(dynamic image) async {
    const cloudName = 'dgc3hbhva';
    const uploadPreset = 'uploads';
    if (kIsWeb && image is Uint8List) {
      var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', image, filename: 'declaration_image.png'),
      );
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(respStr);
        return jsonResp['secure_url'];
      } else {
        debugPrint('Cloudinary error (web): ${response.statusCode}');
        debugPrint('Cloudinary message: $respStr');
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
        debugPrint('Cloudinary error (file): $e');
        return null;
      }
    } else {
      debugPrint('Unsupported image type');
      return null;
    }
  }

  Future<void> _uploadDeclaration() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم اختيار صورة')),
        );
        return;
      }

      String? imageUrl;
      if (kIsWeb) {
        final imageBytes = await image.readAsBytes();
        imageUrl = await uploadImageToCloudinary(imageBytes);
      } else {
        imageUrl = await uploadImageToCloudinary(File(image.path));
      }

      if (imageUrl != null) {
        final imageBytes = kIsWeb ? await image.readAsBytes() : File(image.path);
        setState(() {
          declarationImage = imageBytes;
          declarationImageUrl = imageUrl;
          declarationUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الإقرار بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الإقرار')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء رفع الإقرار: $e')),
      );
    }
  }

  Future<void> _bookAppointment() async {
    if (!declarationUploaded || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى رفع الإقرار وتحديد التاريخ')),
      );
      return;
    }

    setState(() { isLoading = true; });

    try {
      int studentYear = 4;
      int maxPerDay = 2;

      if (studentYear != 4 && studentYear != 5) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن الحجز إلا لطلاب سنة رابعة أو خامسة')),
        );
        return;
      }

      // ✅ جلب الـ STUDENT_UNIVERSITY_ID الحقيقي من قاعدة البيانات
      final String? studentId = Provider.of<LanguageProvider>(context, listen: false).currentUserId;
      String? universityId;

      if (studentId != null && studentId.isNotEmpty) {
        try {
          final studentInfoUrl = Uri.parse('http://localhost:3000/students/$studentId');
          debugPrint('🔍 جلب الرقم الجامعي للطالب: $studentId');
          
          final studentInfoResponse = await http.get(studentInfoUrl);
          
          if (studentInfoResponse.statusCode == 200) {
            final studentData = json.decode(studentInfoResponse.body);
            universityId = studentData['STUDENT_UNIVERSITY_ID'] ?? studentData['student_university_id'];
            debugPrint('✅ تم جلب الرقم الجامعي: $universityId');
          } else {
            debugPrint('❌ فشل جلب الرقم الجامعي: ${studentInfoResponse.statusCode}');
            debugPrint('❌ تفاصيل الخطأ: ${studentInfoResponse.body}');
          }
        } catch (e) {
          debugPrint('❌ خطأ في جلب الرقم الجامعي: $e');
        }
      }

      // استخدام القيمة الافتراضية إذا فشل الجلب
      debugPrint('📝 الرقم الجامعي المستخدم: $universityId');

      // Fetch booking settings
      final bookingSettingsUrl = Uri.parse('http://localhost:3000/bookingSettings');
      final bookingSettingsResponse = await http.get(bookingSettingsUrl);
      if (bookingSettingsResponse.statusCode != 200) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في جلب إعدادات الحجز')),
        );
        return;
      }

      final bookingSettings = json.decode(bookingSettingsResponse.body);
      final int fourthYearLimit = bookingSettings['fourthYearLimit'] ?? 0;
      final int fifthYearLimit = bookingSettings['fifthYearLimit'] ?? 0;

      // Check the student's year
      studentYear = 4;
      maxPerDay = studentYear == 4 ? fourthYearLimit : fifthYearLimit;

      // Fetch the number of appointments for the selected day
      final appointmentsUrl = Uri.parse('http://localhost:3000/appointments/count?date=${selectedDate!.toIso8601String()}');
      final appointmentsResponse = await http.get(appointmentsUrl);
      if (appointmentsResponse.statusCode != 200) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في جلب عدد المواعيد')),
        );
        return;
      }

      final appointmentsData = json.decode(appointmentsResponse.body);
      final int currentAppointments = appointmentsData['count'] ?? 0;

      if (currentAppointments >= maxPerDay) {
        setState(() { isLoading = false; });
        String yearText = studentYear == 4 ? 'رابعة' : 'خامسة';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('عدد الحالات المسموح بها لطلاب السنة $yearText في هذا اليوم هو $maxPerDay فقط. يرجى اختيار يوم آخر للحجز.'),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Update IQRAR in PENDINGUSERS
      final updateUrl = Uri.parse('http://localhost:3000/pendingUsers/${widget.patientUid}');
      final updateIqrarData = {
        'IQRAR': declarationImageUrl,
      };

      debugPrint('📤 إرسال طلب تحديث الإقرار إلى: $updateUrl');
      debugPrint('📄 بيانات التحديث: $updateIqrarData');

      final updateResponse = await http.put(
        updateUrl, 
        body: json.encode(updateIqrarData), 
        headers: {'Content-Type': 'application/json'}
      );

      debugPrint('📥 استجابة تحديث الإقرار: ${updateResponse.statusCode}');
      debugPrint('📥 تفاصيل الاستجابة: ${updateResponse.body}');

      if (updateResponse.statusCode != 200) {
        throw Exception('فشل تحديث الإقرار');
      }

      if (studentId == null || studentId.isEmpty) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد هوية الطالب. يرجى تسجيل الدخول مرة أخرى.')),
        );
        return;
      }

      // ✅ Create appointment مع البيانات المحدثة (بدون الحقول المحذوفة)
      final appointment = {
        'appointment_date': selectedDate!.toIso8601String(),
        'start_time': '8:00 AM', 
        'end_time': '4:00 PM',   
        'student_id': studentId,
        'patient_name': widget.patientName,
        'patient_id_number': widget.patientIdNumber,
        'student_university_id': universityId, 
        'status': 'pending',
      };
      
      final apptUrl = Uri.parse('http://localhost:3000/appointments');
      debugPrint('📤 إرسال طلب حجز الموعد إلى: $apptUrl');
      debugPrint('📄 بيانات الموعد: $appointment');

      final apptResponse = await http.post(
        apptUrl, 
        body: json.encode(appointment), 
        headers: {'Content-Type': 'application/json'}
      );

      debugPrint('📥 استجابة حجز الموعد: ${apptResponse.statusCode}');
      debugPrint('📥 تفاصيل الاستجابة: ${apptResponse.body}');

      if (apptResponse.statusCode != 201) {
        throw Exception('فشل حجز الموعد');
      }

      setState(() { isLoading = false; });
      if (!mounted) return;
      
      // Show success dialog
      _showSuccessDialog();
      
    } catch (e) {
      setState(() { isLoading = false; });
      debugPrint('❌ خطأ أثناء حجز الموعد: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حجز الموعد: $e')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('تم الحجز بنجاح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تم حجز الموعد بنجاح للمريض:'),
              SizedBox(height: 8),
              Text(widget.patientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 5),
              Text('التاريخ: ${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'),
              SizedBox(height: 12),
              Text('سيتم مراجعة طلبك وإشعارك بالنتيجة', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('موافق', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز موعد للفحص الأولي'),
        backgroundColor: const Color(0xFF2A7A94),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Info Section
                    Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF2A7A94)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.patientIdNumber, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1.2),
                    
                    // Declaration Section
                    Text(
                      '1. رفع صورة الإقرار', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue[900], 
                        fontSize: 16
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: Text(
                        declarationUploaded ? 'تغيير الإقرار' : 'رفع الإقرار',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A7A94),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _uploadDeclaration,
                    ),
                    if (declarationImage != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.teal, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.memory(
                                    declarationImage as Uint8List, 
                                    width: 180, 
                                    height: 180, 
                                    fit: BoxFit.cover
                                  )
                                : Image.file(
                                    declarationImage as File, 
                                    width: 180, 
                                    height: 180, 
                                    fit: BoxFit.cover
                                  ),
                          ),
                        ),
                      ),
                    ],
                    if (declarationUploaded) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 5),
                          Text(
                            'تم رفع الإقرار بنجاح',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Date Selection Section
                    Text(
                      '2. اختيار تاريخ الحجز', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue[900], 
                        fontSize: 16
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      label: Text(
                        selectedDate == null ? 'اختر تاريخ الحجز' : '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedDate == null ? Color(0xFF2A7A94) : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickDate,
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, color: Colors.green, size: 18),
                          SizedBox(width: 5),
                          Text(
                            'تم اختيار التاريخ',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Book Button
                    ElevatedButton.icon(
                      icon: isLoading 
                          ? const SizedBox(
                              height: 22, 
                              width: 22, 
                              child: CircularProgressIndicator(
                                color: Colors.white, 
                                strokeWidth: 2.5
                              ),
                            )
                          : const Icon(Icons.check_circle, color: Colors.white),
                      onPressed: (declarationUploaded && selectedDate != null && !isLoading) 
                          ? _bookAppointment 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (declarationUploaded && selectedDate != null) 
                            ? const Color(0xFF2A7A94) 
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      label: isLoading
                          ? const Text('جاري الحجز...', style: TextStyle(color: Colors.white))
                          : const Text('تأكيد الحجز', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}