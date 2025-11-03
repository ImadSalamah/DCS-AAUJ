// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AssignPatientsAdminPage extends StatefulWidget {
  const AssignPatientsAdminPage({super.key});

  @override
  State<AssignPatientsAdminPage> createState() => _AssignPatientsAdminPageState();
}

class _AssignPatientsAdminPageState extends State<AssignPatientsAdminPage> {
  final String _apiBaseUrl = 'http://localhost:3000';
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _currentAssignments = [];
  String? _selectedPatientId;
  List<String> _selectedStudentIds = [];
  bool _isLoading = true;
  bool _saving = false;
  bool _clearing = false;
  String _patientSearchQuery = '';
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final studentsResponse = await http.get(Uri.parse('$_apiBaseUrl/students'));
      final patientsResponse = await http.get(Uri.parse('$_apiBaseUrl/patients'));
      
      http.Response assignmentsResponse;
      try {
        assignmentsResponse = await http.get(Uri.parse('$_apiBaseUrl/patient_assignments'));
      } catch (e) {
        assignmentsResponse = http.Response('[]', 200);
      }

      if (studentsResponse.statusCode == 200 && patientsResponse.statusCode == 200) {
        
        final students = List<Map<String, dynamic>>.from(json.decode(studentsResponse.body));
        final patients = List<Map<String, dynamic>>.from(json.decode(patientsResponse.body));
        
        List<Map<String, dynamic>> assignments = [];
        if (assignmentsResponse.statusCode == 200) {
          try {
            assignments = List<Map<String, dynamic>>.from(json.decode(assignmentsResponse.body));
          } catch (e) {
            assignments = [];
          }
        }
        
        setState(() {
          _students = students;
          _patients = patients;
          _currentAssignments = assignments;
          _isLoading = false;
        });
        
      } else {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في تحميل البيانات الأساسية')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال بالسيرفر: $e')),
      );
    }
  }

  Future<void> _assignPatientToStudents() async {
    if (_selectedPatientId == null || _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار مريض وطالب واحد على الأقل')),
      );
      return;
    }

    setState(() { _saving = true; });
    try {
      bool allSuccess = true;
      List<String> newStudentIds = [];
      
      for (String studentId in _selectedStudentIds) {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/assign_patient_to_student'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'patient_id': _selectedPatientId,
            'student_id': studentId,
          }),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          newStudentIds.add(studentId);
        } else {
          allSuccess = false;
          json.decode(response.body);
        }
      }
      
      setState(() { _saving = false; });
      
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تعيين المريض لـ ${newStudentIds.length} طالب بنجاح')),
        );
        await _loadData();
        _resetSelections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في تعيين بعض الطلاب')),
        );
      }
    } catch (e) {
      setState(() { _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التعيين: $e')),
      );
    }
  }

  Future<void> _removePatientAssignment(String patientId) async {
    setState(() { _saving = true; });
    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/remove_patient_assignment/$patientId'),
      );
      
      setState(() { _saving = false; });
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إزالة تعيين المريض بنجاح')),
        );
        await _loadData();
        _resetSelections();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? 'فشل في الإزالة')),
        );
    }
    } catch (e) {
    setState(() { _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الإزالة: $e')),
      );
    }
  }

  Future<void> _clearAllAssignments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف الكلي'),
        content: const Text('هل أنت متأكد أنك تريد إزالة جميع تعيينات المرضى؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() { _clearing = true; });
    try {
      final response = await http.delete(Uri.parse('$_apiBaseUrl/clear_all_assignments'));
      setState(() { _clearing = false; });
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إزالة جميع التعيينات بنجاح')),
        );
        await _loadData();
        _resetSelections();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إزالة التعيينات')),
        );
      }
    } catch (e) {
      setState(() { _clearing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إزالة التعيينات: $e')),
      );
    }
  }

  void _resetSelections() {
    setState(() {
      _selectedPatientId = null;
      _selectedStudentIds.clear();
    });
  }

  String _getFullName(Map<String, dynamic> user) {
    final first = user['FIRSTNAME']?.toString() ?? '';
    final father = user['FATHERNAME']?.toString() ?? '';
    final grandfather = user['GRANDFATHERNAME']?.toString() ?? '';
    final family = user['FAMILYNAME']?.toString() ?? '';
    
    return [first, father, grandfather, family]
        .where((e) => (e.isNotEmpty))
        .join(' ');
  }

  String _getPatientId(Map<String, dynamic> patient) {
    return patient['ID']?.toString() ?? '';
  }

  String _getStudentId(Map<String, dynamic> student) {
    return student['ID']?.toString() ?? '';
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_patientSearchQuery.isEmpty) return _patients;
    final query = _patientSearchQuery.toLowerCase();
    return _patients.where((patient) {
      final fullName = _getFullName(patient).toLowerCase();
      final idNumber = (patient['IDNUMBER']?.toString() ?? '').toLowerCase();
      return fullName.contains(query) || idNumber.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_studentSearchQuery.isEmpty) return _students;
    final query = _studentSearchQuery.toLowerCase();
    return _students.where((student) {
      final fullName = _getFullName(student).toLowerCase();
      final universityId = (student['STUDENT_UNIVERSITY_ID']?.toString() ?? student['UNIVERSITYID']?.toString() ?? '').toLowerCase();
      return fullName.contains(query) || universityId.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _getAssignedStudentsForPatient(String patientId) {
    return _currentAssignments.where((assignment) {
      return assignment['PATIENT_UID']?.toString() == patientId;
      }).toList();
    }

  bool _isPatientAssigned(String patientId) {
    return _currentAssignments.any((assignment) => assignment['PATIENT_UID']?.toString() == patientId);
  }

  List<String> _getAssignedStudentNames(String patientId) {
    final assignments = _getAssignedStudentsForPatient(patientId);
    List<String> names = [];
    
    for (var assignment in assignments) {
      final studentId = assignment['STUDENT_ID']?.toString();
      final student = _students.firstWhere(
        (s) => _getStudentId(s) == studentId,
        orElse: () => <String, dynamic>{},
      );
      if (student.isNotEmpty) {
        names.add(_getFullName(student));
      }
    }
    
    return names;
  }

  List<String> _getAssignedStudentIds(String patientId) {
    final assignments = _getAssignedStudentsForPatient(patientId);
    List<String> ids = [];
    
    for (var assignment in assignments) {
      final studentId = assignment['STUDENT_ID']?.toString();
      if (studentId != null && studentId.isNotEmpty) {
        ids.add(studentId);
      }
    }
    
    return ids;
  }


  void _showAddStudentsDialog(String patientId) {
    final assignedStudentIds = _getAssignedStudentIds(patientId);
    
    setState(() {
      _selectedPatientId = patientId;
      _selectedStudentIds = List.from(assignedStudentIds);
    });
  }

  void _showDeleteOptionsDialog(String patientId) {
    final assignedStudents = _getAssignedStudentsForPatient(patientId);
    final assignedStudentNames = _getAssignedStudentNames(patientId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خيارات حذف التعيين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assignedStudents.isNotEmpty) ...[
              const Text('هذا المريض معين حالياً للطلاب:'),
              const SizedBox(height: 8),
              ...assignedStudentNames.map((name) => 
                Text('• $name', style: const TextStyle(fontWeight: FontWeight.bold))
              ),
              const SizedBox(height: 16),
            ],
            const Text('اختر الإجراء المطلوب:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removePatientAssignment(patientId);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('حذف تعيين هذا المريض فقط'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllAssignments();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف جميع التعيينات'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2A7A94);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة تعيين المرضى للطلاب'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatsCard(),
                  _buildPatientSearchSection(),
                  if (_selectedPatientId != null) 
                    _buildStudentSelectionSection(),
                  _buildPatientsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('المرضى', _patients.length, Icons.people),
            _buildStatItem('الطلاب', _students.length, Icons.school),
            _buildStatItem('التعيينات', _currentAssignments.length, Icons.assignment),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2A7A94)),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPatientSearchSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const Text(
              'ابحث عن المريض:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحث باسم المريض أو رقم الهوية',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => setState(() => _patientSearchQuery = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelectionSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الطلاب المسؤولين:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم الطالب أو الرقم الجامعي',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
              onChanged: (val) => setState(() => _studentSearchQuery = val),
            ),
            const SizedBox(height: 12),
            _buildSelectedPatientInfo(),
            const SizedBox(height: 12),
            _buildStudentSelectionList(),
            const SizedBox(height: 12),
            if (_selectedStudentIds.isNotEmpty) 
              _buildActionButtons(),
          ],
        ),
                    ),
    );
  }

  Widget _buildStudentSelectionList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _filteredStudents.isEmpty
            ? const Center(child: Text('لا توجد طلاب متاحين'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  final studentId = _getStudentId(student);
                                final name = _getFullName(student);
                  final universityId = student['STUDENT_UNIVERSITY_ID']?.toString() ?? student['UNIVERSITYID']?.toString() ?? '';
                  final isSelected = _selectedStudentIds.contains(studentId);
                  
                  final isCurrentlyAssigned = _selectedPatientId != null && 
                      _getAssignedStudentIds(_selectedPatientId!).contains(studentId);
                  
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : 'بدون اسم',
                            style: TextStyle(
                              fontWeight: isCurrentlyAssigned ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCurrentlyAssigned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'معين حالياً',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: universityId.isNotEmpty ? Text('الرقم الجامعي: $universityId') : null,
                    value: isSelected,
                    onChanged: (bool? value) {
                                    setState(() {
                        if (value == true) {
                          _selectedStudentIds.add(studentId);
                        } else {
                          _selectedStudentIds.remove(studentId);
                        }
                      });
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSelectedPatientInfo() {
    final patient = _patients.firstWhere(
      (p) => _getPatientId(p) == _selectedPatientId,
      orElse: () => <String, dynamic>{},
    );
    
    if (patient.isEmpty) return const SizedBox();
    
    final name = _getFullName(patient);
    final idNumber = patient['IDNUMBER']?.toString() ?? '';
    final assignedStudents = _getAssignedStudentsForPatient(_selectedPatientId!);
    final assignedStudentNames = _getAssignedStudentNames(_selectedPatientId!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المريض المختار: ${name.isNotEmpty ? name : "بدون اسم"}', 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        if (idNumber.isNotEmpty) Text('رقم الهوية: $idNumber'),
        if (assignedStudents.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 4),
                                    Text(
                      'مُعين حالياً لـ ${assignedStudents.length} طالب',
                      style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                                    ),
                  ],
                ),
                if (assignedStudentNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                                      Text(
                    'الطلاب المعينين: ${assignedStudentNames.join("، ")}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  '✅ يمكنك إضافة طلاب جدد أو إزالة الطلاب الحاليين',
                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
          ),
        ]
      ],
    );
  }

  Widget _buildActionButtons() {
    final selectedStudentsCount = _selectedStudentIds.length;
    final assignedStudentIds = _selectedPatientId != null ? _getAssignedStudentIds(_selectedPatientId!) : [];
    final newStudentsCount = _selectedStudentIds.where((id) => !assignedStudentIds.contains(id)).length;
    final removedStudentsCount = assignedStudentIds.where((id) => !_selectedStudentIds.contains(id)).length;
    
    return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
        const Divider(),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تم اختيار $selectedStudentsCount طالب', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (newStudentsCount > 0) 
              Text('➕ سيتم إضافة $newStudentsCount طالب جديد',
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
            if (removedStudentsCount > 0)
              Text('➖ سيتم إزالة $removedStudentsCount طالب',
                  style: const TextStyle(fontSize: 12, color: Colors.red)),
            if (newStudentsCount == 0 && removedStudentsCount == 0)
              Text('🔄 لم يتم إجراء أي تغييرات',
                  style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ],
                                      ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: _saving ? null : _assignPatientToStudents,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A7A94),
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ التغييرات'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _resetSelections,
              child: const Text('إلغاء'),
                                      ),
                                    ],
                                  ),
      ],
    );
  }

  Widget _buildPatientsList() {
    return Column(
      children: [
                                Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قائمة المرضى (${_filteredPatients.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton.icon(
                onPressed: _clearing ? null : () => _showDeleteOptionsDialog('all'),
                icon: _clearing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.delete_forever),
                label: const Text('حذف التعيينات'),
                                    style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                ),
                              ],
                            ),
                    ),
        _filteredPatients.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد نتائج للبحث',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = _filteredPatients[index];
                  final patientId = _getPatientId(patient);
                  final name = _getFullName(patient);
                  final idNumber = patient['IDNUMBER']?.toString() ?? '';
                  final isAssigned = _isPatientAssigned(patientId);
                  final assignedStudents = _getAssignedStudentsForPatient(patientId);
                  final assignedStudentNames = _getAssignedStudentNames(patientId);
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(name.isNotEmpty ? name : 'بدون اسم'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (idNumber.isNotEmpty) Text('رقم الهوية: $idNumber'),
                          if (isAssigned) ...[
                            const SizedBox(height: 4),
                            Text(
                              'معين لـ ${assignedStudents.length} طالب',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            if (assignedStudentNames.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'الطلاب: ${assignedStudentNames.join("، ")}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ]
                          ]
                        ],
                      ),
                      leading: Icon(
                        isAssigned ? Icons.check_circle : Icons.person_outline,
                        color: isAssigned ? Colors.green : Colors.grey,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAssigned)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _saving ? null : () => _showDeleteOptionsDialog(patientId),
                              tooltip: 'خيارات الحذف',
                            ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              _showAddStudentsDialog(patientId);
                            },
                            tooltip: 'إضافة/تعديل تعيين',
                          ),
                        ],
                      ),
                      onTap: () {
                        _showAddStudentsDialog(patientId);
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }
}