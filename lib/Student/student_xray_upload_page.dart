// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class StudentXrayUploadPage extends StatefulWidget {
  final String studentId;
  
  const StudentXrayUploadPage({super.key, required this.studentId});

  @override
  State<StudentXrayUploadPage> createState() => _StudentXrayUploadPageState();
}

class _StudentXrayUploadPageState extends State<StudentXrayUploadPage> {
  XFile? xrayImage;
  Uint8List? xrayImageBytes;
  bool _isUploading = false;
  List<Map<String, dynamic>> requests = [];
  Map<String, dynamic>? selectedRequest;
  bool _loadingRequests = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // دالة رفع الصورة إلى Cloudinary
  Future<String?> uploadImageToCloudinary(dynamic image, {String? folder}) async {
    const cloudName = 'dgc3hbhva';
    const uploadPreset = 'uploads';
    
    try {
      if (kIsWeb && image is Uint8List) {
        var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
        var request = http.MultipartRequest('POST', uri);
        
        request.fields['upload_preset'] = uploadPreset;
        if (folder != null) {
          request.fields['folder'] = folder;
        }
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', 
            image, 
            filename: 'xray_${DateTime.now().millisecondsSinceEpoch}.jpg'
          ),
        );
        
        var response = await request.send();
        final respStr = await response.stream.bytesToString();
        
        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(respStr);
          debugPrint('✅ تم رفع صورة الأشعة إلى Cloudinary: ${jsonResp['secure_url']}');
          return jsonResp['secure_url'];
        } else {
          debugPrint('❌ خطأ Cloudinary: ${response.statusCode} - $respStr');
          return null;
        }
        
      } else if (image is XFile) {
        final bytes = await image.readAsBytes();
        return uploadImageToCloudinary(bytes, folder: folder);
      } else {
        debugPrint('❌ نوع الصورة غير مدعوم');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة إلى Cloudinary: $e');
      return null;
    }
  }

  Future<void> _fetchRequests() async {
    setState(() { _loadingRequests = true; });
    
    try {
      final url = Uri.parse('http://localhost:3000/student-xray-requests/${widget.studentId}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final requestsData = List<Map<String, dynamic>>.from(data['data']);
          
          // طباعة عينة من البيانات للتأكد
          if (requestsData.isNotEmpty) {
            
            // طباعة جميع المفاتيح للتأكد
          }
          
          setState(() { 
            requests = requestsData; 
            _loadingRequests = false; 
          });
        } else {
          setState(() { 
            requests = []; 
            _loadingRequests = false; 
          });
        }
      } else {
        setState(() { 
          requests = []; 
          _loadingRequests = false; 
        });
      }
    } catch (e) {
      setState(() { 
        requests = []; 
        _loadingRequests = false; 
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        
        if (bytes.length > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حجم الصورة كبير جداً. الحد الأقصى 10MB'))
          );
          return;
        }
        
        setState(() {
          xrayImage = picked;
          xrayImageBytes = bytes;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم اختيار الصورة بنجاح'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في اختيار الصورة'))
      );
    }
  }

  void _removeImage() {
    setState(() {
      xrayImage = null;
      xrayImageBytes = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إزالة الصورة'))
    );
  }

  Future<void> _uploadXrayImage() async {
    if (xrayImageBytes == null || selectedRequest == null) return;
    
    setState(() { _isUploading = true; });
    
    try {
      // 1. رفع الصورة إلى Cloudinary
      debugPrint('☁️ جاري رفع الصورة إلى Cloudinary...');
      String? cloudinaryUrl = await uploadImageToCloudinary(
        xrayImageBytes!,
        folder: 'dental_xrays'
      );

      if (cloudinaryUrl != null) {
        debugPrint('✅ تم الرفع إلى Cloudinary: $cloudinaryUrl');
        
        // 2. إرسال الرابط إلى السيرفر
        debugPrint('📤 جاري إرسال الرابط إلى السيرفر...');
        final updateUrl = Uri.parse('http://localhost:3000/update-xray-image-url');
        
        final requestId = selectedRequest!['request_id'];
        
        final updateData = {
          'requestId': requestId,
          'studentId': widget.studentId,
          'imageUrl': cloudinaryUrl,
        };

        debugPrint('📄 بيانات التحديث: $updateData');

        final response = await http.patch(
          updateUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(updateData),
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          
          if (result['success'] == true) {
            debugPrint('✅ تم تحديث الطلب في قاعدة البيانات');
            
            setState(() { 
              _isUploading = false; 
              selectedRequest = null; 
              xrayImage = null; 
              xrayImageBytes = null; 
            });
            
            // إعادة تحميل قائمة الطلبات
            await _fetchRequests();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ تم رفع صورة الأشعة بنجاح'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              )
            );
          } else {
            throw Exception(result['error'] ?? 'فشل في تحديث البيانات');
          }
        } else {
          throw Exception('فشل في الاتصال بالخادم: ${response.statusCode}');
        }
      } else {
        throw Exception('فشل في رفع الصورة إلى Cloudinary');
      }
    } catch (e) {
      setState(() { _isUploading = false; });
      debugPrint('❌ خطأ في الرفع: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    const Color primaryColor = Color(0xFF2A7A94);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع صورة الأشعة'),
        backgroundColor: primaryColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequests,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _loadingRequests
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد طلبات أشعة',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : selectedRequest == null
                  ? _buildRequestsList()
                  : _buildUploadForm(),
    );
  }

 Widget _buildRequestsList() {
  // فلترة الطلبات: إظهار فقط الطلبات المكتملة بدون صور
  final pendingRequests = requests.where((req) {
    final status = req['status'];
    final cloudinaryUrl = req['cloudinary_url'];
    
    debugPrint('🔍 فحص الطلب: ${req['request_id']}');
    debugPrint('   - STATUS: $status');
    debugPrint('   - CLOUDINARY_URL: $cloudinaryUrl');
    
    // ✅ الشرط الجديد: إظهار الطلب فقط إذا:
    // STATUS = 'completed' و cloudinary_url = null
    final shouldShow = status == 'completed' && cloudinaryUrl == null;
    
    debugPrint('   - يعرض: $shouldShow');
    return shouldShow;
  }).toList();

  debugPrint('📋 عدد الطلبات المعلقة: ${pendingRequests.length} من أصل ${requests.length}');

  if (pendingRequests.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'لا توجد طلبات أشعة معلقة',
            style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'جميع طلباتك تم رفع صورها بنجاح',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    itemCount: pendingRequests.length,
    itemBuilder: (context, idx) {
      final req = pendingRequests[idx];
      final patientName = req['patient_name'] ?? 'غير محدد';
      final xrayType = req['xray_type'] ?? 'غير محدد';
      final jaw = req['jaw'];
      final tooth = req['tooth'];
      final side = req['side'];
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          leading: const Icon(
            Icons.warning_amber,
            color: Colors.red,
          ),
          title: Text(
            'المريض: $patientName',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نوع الأشعة: $xrayType'),
              if (jaw != null && jaw.toString().isNotEmpty) 
                Text('الفك: $jaw'),
              if (side != null && side.toString().isNotEmpty) 
                Text('الجهة: $side'),
              if (tooth != null && tooth.toString().isNotEmpty) 
                Text('السن: $tooth'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ناقص صورة',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() { 
              selectedRequest = req; 
              xrayImage = null; 
              xrayImageBytes = null; 
            });
          },
        ),
      );
    },
  );
}
  
  Widget _buildUploadForm() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;
    const Color primaryColor = Color(0xFF2A7A94);

    // استخراج البيانات مع قيم افتراضية
    final patientName = selectedRequest!['patient_name'] ?? 'غير محدد';
    final xrayType = selectedRequest!['xray_type'] ?? 'غير محدد';
    final jaw = selectedRequest!['jaw'];
    final side = selectedRequest!['side'];
    final tooth = selectedRequest!['tooth'];
    final createdAt = selectedRequest!['created_at'];

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.06 > 32 ? 32 : size.width * 0.06,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الطلب
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل طلب الأشعة', 
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('المريض:', patientName),
                    _buildInfoRow('نوع الأشعة:', xrayType),
                    if (jaw != null && jaw.toString().isNotEmpty) 
                      _buildInfoRow('الفك:', jaw.toString()),
                    if (side != null && side.toString().isNotEmpty) 
                      _buildInfoRow('الجهة:', side.toString()),
                    if (tooth != null && tooth.toString().isNotEmpty) 
                      _buildInfoRow('رقم السن:', tooth.toString()),
                    _buildInfoRow('تاريخ الطلب:', _formatDate(createdAt)),
                    
                    // حالة الطلب
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending, color: Colors.orange[700], size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'بانتظار رفع الصورة',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // معاينة الصورة
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'صورة الأشعة', 
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: xrayImageBytes != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    xrayImageBytes!, 
                                    height: size.height * 0.25, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: size.height * 0.25,
                                        color: Colors.grey[200],
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.red),
                                            SizedBox(height: 8),
                                            Text('خطأ في تحميل الصورة'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.photo, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              height: size.height * 0.25,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'لم يتم اختيار صورة', 
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // أزرار التحكم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('اختيار من المعرض'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (xrayImageBytes != null)
                          ElevatedButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete),
                            label: const Text('إزالة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // زر الرفع
            Center(
              child: SizedBox(
                width: size.width * 0.7,
                height: 50,
                child: ElevatedButton(
                  onPressed: xrayImageBytes != null && !_isUploading ? _uploadXrayImage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: xrayImageBytes != null ? primaryColor : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2, 
                                color: Colors.white
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('جاري الرفع إلى Cloudinary...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text('رفع الصورة'),
                          ],
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() { 
                    selectedRequest = null; 
                    xrayImage = null; 
                    xrayImageBytes = null; 
                  });
                },
                child: const Text('رجوع إلى قائمة الطلبات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'غير محدد'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'غير محدد';
    
    try {
      final dateStr = date.toString();
      if (dateStr.contains('T')) {
        return dateStr.split('T').first;
      }
      return dateStr.split(' ').first;
    } catch (e) {
      return date.toString();
    }
  }
}