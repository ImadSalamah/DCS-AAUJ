// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Doctor/doctor_sidebar.dart';
import '../loginpage.dart';

class ClinicalProceduresForm extends StatefulWidget {
  final String uid;
  const ClinicalProceduresForm({super.key, required this.uid});

  @override
  State<ClinicalProceduresForm> createState() => _ClinicalProceduresFormState();
}

class _ClinicalProceduresFormState extends State<ClinicalProceduresForm> {
  final String apiBaseUrl = 'http://localhost:3000'; 
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final TextEditingController _dateOfOperationController = TextEditingController();
  final TextEditingController _typeOfOperationController = TextEditingController();
  final TextEditingController _toothNoController = TextEditingController();
  final TextEditingController _dateOfSecondVisitController = TextEditingController();
  final TextEditingController _supervisorNameController = TextEditingController();
  
  // Clinic selection
  String? _selectedClinic;
  final List<String> _clinics = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'
  ];
  
  // Student search
  final TextEditingController _studentSearchController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> foundStudents = [];
  String? _selectedStudentName;
  int? selectedStudentIndex;
  String? studentError;
  bool isSearchingStudent = false;
  
  // Patient search
  final TextEditingController _patientSearchController = TextEditingController();
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> foundPatients = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _selectedPatientIdNumber;
  int? selectedPatientIndex;
  String? patientError;
  bool isSearchingPatient = false;
  
  // Doctor info
  String? _currentDoctorName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _fetchCurrentDoctorName(),
        _loadStudents(),
        _loadPatients()
      ]);
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCurrentDoctorName() async {
    if (widget.uid.isEmpty) {
      _setUnknownSupervisor();
      return;
    }

    try {
      // Try doctors endpoint first
      final doctorResponse = await http.get(Uri.parse('$apiBaseUrl/doctors/${widget.uid}'));
      
      if (doctorResponse.statusCode == 200) {
        final doctorData = json.decode(doctorResponse.body) as Map<String, dynamic>;
        final fullName = _getFullName(doctorData);
        
        setState(() {
          _currentDoctorName = fullName;
          _supervisorNameController.text = _currentDoctorName!;
        });
        return;
      }
      
      // Fallback to users endpoint
      final userResponse = await http.get(Uri.parse('$apiBaseUrl/users/${widget.uid}'));
      
      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body) as Map<String, dynamic>;
        final fullName = _getFullName(userData);
        
        setState(() {
          _currentDoctorName = fullName;
          _supervisorNameController.text = _currentDoctorName!;
        });
        return;
      }
      
      _setUnknownSupervisor();
      
    } catch (e) {
      _setUnknownSupervisor();
    }
  }

  void _setUnknownSupervisor() {
    setState(() {
      _currentDoctorName = 'Unknown Supervisor';
      _supervisorNameController.text = _currentDoctorName!;
    });
  }

  String _getFullName(Map<String, dynamic> user) {
    final fullName = user['FULL_NAME']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    
    final first = user['FIRST_NAME']?.toString().trim() ?? '';
    final father = user['FATHER_NAME']?.toString().trim() ?? '';
    final grandfather = user['GRANDFATHER_NAME']?.toString().trim() ?? '';
    final family = user['FAMILY_NAME']?.toString().trim() ?? '';
    
    final builtName = [first, father, grandfather, family].where((e) => e.isNotEmpty).join(' ');
    
    return builtName.isEmpty ? 'Unknown User' : builtName;
  }

  Future<void> _loadStudents() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/students-with-users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          students = data.map((studentData) {
            return {
              'id': studentData['id']?.toString() ?? studentData['userId']?.toString() ?? '',
              'userId': studentData['userId']?.toString() ?? studentData['id']?.toString() ?? '',
              'firstName': studentData['firstName']?.toString() ?? '',
              'fatherName': studentData['fatherName']?.toString() ?? '',
              'grandfatherName': studentData['grandfatherName']?.toString() ?? '',
              'familyName': studentData['familyName']?.toString() ?? '',
              'fullName': studentData['fullName']?.toString() ?? 'Student without name',
              'username': studentData['username']?.toString() ?? '',
              'email': studentData['email']?.toString() ?? '',
              'phone': studentData['phone']?.toString() ?? '',
              'role': studentData['role']?.toString() ?? '',
              'isActive': studentData['isActive'] ?? 1,
              'idNumber': studentData['idNumber']?.toString() ?? '',
              'gender': studentData['gender']?.toString() ?? '',
              'birthDate': studentData['birthDate']?.toString() ?? '',
              'address': studentData['address']?.toString() ?? '',
              'image': studentData['image']?.toString() ?? '',
              'studentId': studentData['studentId']?.toString() ?? '',
              'universityId': studentData['universityId']?.toString() ?? studentData['studentUniversityId']?.toString() ?? '',
              'studentUniversityId': studentData['studentUniversityId']?.toString() ?? studentData['universityId']?.toString() ?? '',
            };
          }).toList();
        });
        
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> _loadPatients() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/patients'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          patients = data.cast<Map<String, dynamic>>();
        });
        
      } else {
      }
    } catch (e) {
    }
  }

  // Patient Search
  void searchPatient() {
    final query = _patientSearchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        foundPatients = [];
        patientError = null;
      });
      return;
    }

    setState(() { 
      isSearchingPatient = true;
      foundPatients = [];
      patientError = null;
    });

    final filtered = patients.where((patient) {
      final searchQuery = query.toLowerCase();
      
      final firstName = patient['FIRSTNAME']?.toString().toLowerCase() ?? '';
      final fatherName = patient['FATHERNAME']?.toString().toLowerCase() ?? '';
      final grandfatherName = patient['GRANDFATHERNAME']?.toString().toLowerCase() ?? '';
      final familyName = patient['FAMILYNAME']?.toString().toLowerCase() ?? '';
      final fullName = patient['FULL_NAME']?.toString().toLowerCase() ?? '';
      
      final name = [
        firstName, fatherName, grandfatherName, familyName, fullName
      ].where((e) => e.isNotEmpty).join(' ');

      final idNumber = patient['IDNUMBER']?.toString().toLowerCase() ?? '';
      final patientId = patient['PATIENT_UID']?.toString().toLowerCase() ?? '';
      final medicalRecord = patient['MEDICAL_RECORD_NO']?.toString().toLowerCase() ?? '';

      return name.contains(searchQuery) || 
             idNumber.contains(searchQuery) ||
             patientId.contains(searchQuery) ||
             medicalRecord.contains(searchQuery);
    }).toList();

    setState(() {
      foundPatients = filtered;
      patientError = filtered.isEmpty ? 'No patient found' : null;
      isSearchingPatient = false;
    });
  }

  // Student Search
  void searchStudent() {
    final query = _studentSearchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        foundStudents = [];
        studentError = null;
        isSearchingStudent = false;
      });
      return;
    }

    setState(() { 
      isSearchingStudent = true;
      foundStudents = [];
      studentError = null;
    });

    final filtered = students.where((student) {
      final searchQuery = query.toLowerCase();
      
      final fieldsToSearch = [
        student['fullName']?.toString().toLowerCase() ?? '',
        student['firstName']?.toString().toLowerCase() ?? '',
        student['fatherName']?.toString().toLowerCase() ?? '',
        student['grandfatherName']?.toString().toLowerCase() ?? '',
        student['familyName']?.toString().toLowerCase() ?? '',
        student['universityId']?.toString().toLowerCase() ?? '',
        student['studentUniversityId']?.toString().toLowerCase() ?? '',
        student['id']?.toString().toLowerCase() ?? '',
        student['userId']?.toString().toLowerCase() ?? '',
        student['username']?.toString().toLowerCase() ?? '',
        student['idNumber']?.toString().toLowerCase() ?? '',
      ];
      
      return fieldsToSearch.any((field) => field.contains(searchQuery));
    }).toList();

    setState(() {
      foundStudents = filtered;
      studentError = filtered.isEmpty ? 'No student found' : null;
      isSearchingStudent = false;
    });
  }

  String _generateProcedureId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'PROC_${timestamp}_$random';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatientIdNumber == null) {
        _showErrorSnackBar('Please select a valid patient');
        return;
      }

      if (_currentDoctorName == null || _currentDoctorName!.isEmpty || _currentDoctorName == 'Unknown Supervisor') {
        _showErrorSnackBar('Cannot determine supervisor name');
        return;
      }

      final procedureData = {
        'PROCEDURE_ID': _generateProcedureId(),
        'CLINIC_NAME': _selectedClinic,
        'DATE_OF_OPERATION': _dateOfOperationController.text,
        'DATE_OF_SECOND_VISIT': _dateOfSecondVisitController.text.isNotEmpty 
            ? _dateOfSecondVisitController.text 
            : null,
        'PATIENT_ID': _selectedPatientId,
        'PATIENT_ID_NUMBER': _selectedPatientIdNumber,
        'PATIENT_NAME': _selectedPatientName,
        'STUDENT_NAME': _selectedStudentName,
        'SUPERVISOR_NAME': _supervisorNameController.text,
        'TOOTH_NO': _toothNoController.text,
        'TYPE_OF_OPERATION': _typeOfOperationController.text,
      };


      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/clinical_procedures'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(procedureData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSuccessSnackBar('Clinical procedure saved successfully!');
          _resetForm();
        } else {
          _showErrorSnackBar('Failed to save clinical procedure: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorSnackBar('Error saving clinical procedure: $e');
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _dateOfOperationController.clear();
    _typeOfOperationController.clear();
    _toothNoController.clear();
    _dateOfSecondVisitController.clear();
    _studentSearchController.clear();
    _patientSearchController.clear();
    
    setState(() {
      _selectedClinic = null;
      _selectedPatientId = null;
      _selectedPatientName = null;
      _selectedPatientIdNumber = null;
      _selectedStudentName = null;
      selectedPatientIndex = null;
      selectedStudentIndex = null;
      foundPatients = [];
      foundStudents = [];
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A7A94);
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 20),
              Text('Loading data...', style: TextStyle(color: primaryColor)),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Clinical Procedures Form', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: DoctorSidebar(
        userRole: 'doctor',
        primaryColor: const Color(0xFF2A7A94),
        accentColor: Colors.teal,
        userName: _currentDoctorName ?? '',
        userImageUrl: null,
        onLogout: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
        parentContext: context,
        collapsed: false,
        translate: (ctx, txt) => txt,
        doctorUid: widget.uid,
        allowedFeatures: const [
          'waiting_list',
          'clinical_procedures_form',
          'students_evaluation',
          'supervision_groups',
          'examined_patients',
          'prescription',
          'xray_request',
          'assign_patients_to_students',
        ],
      ),
      body: Container(
        color: primaryColor.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Debug Information
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Debug Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('UID: ${widget.uid}'),
                        Text('Supervisor: ${_currentDoctorName ?? "Loading..."}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Patient Search Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _patientSearchController,
                                decoration: InputDecoration(
                                  labelText: 'Search patient (name or ID)',
                                  prefixIcon: const Icon(Icons.person_search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (_) => searchPatient(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: isSearchingPatient
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.search),
                              onPressed: isSearchingPatient ? null : searchPatient,
                            ),
                          ],
                        ),
                        if (patientError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              patientError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Patient Search Results
                if (foundPatients.isNotEmpty && selectedPatientIndex == null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Search Results (${foundPatients.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...foundPatients.asMap().entries.map((entry) {
                            final i = entry.key;
                            final patient = entry.value;
                            
                            final patientName = [
                              patient['FIRSTNAME'] ?? '',
                              patient['FATHERNAME'] ?? '',
                              patient['GRANDFATHERNAME'] ?? '',
                              patient['FAMILYNAME'] ?? ''
                            ].where((e) => e != '').join(' ');
                            
                            final displayName = patientName.isNotEmpty 
                                ? patientName 
                                : patient['FULL_NAME'] ?? 'Patient without name';
                            
                            final idNumber = patient['IDNUMBER'] ?? patient['PATIENT_UID'] ?? 'N/A';
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: selectedPatientIndex == i ? Colors.blue[50] : null,
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(displayName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID Number: $idNumber'),
                                    if (patient['MEDICAL_RECORD_NO'] != null)
                                      Text('Medical Record: ${patient['MEDICAL_RECORD_NO']}'),
                                  ],
                                ),
                                trailing: selectedPatientIndex == i
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  setState(() {
                                    selectedPatientIndex = i;
                                    _selectedPatientId = patient['PATIENT_UID'] ?? patient['IDNUMBER']?.toString();
                                    _selectedPatientName = displayName;
                                    _selectedPatientIdNumber = patient['IDNUMBER']?.toString();
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                // Selected Patient
                if (selectedPatientIndex != null && foundPatients.isNotEmpty && selectedPatientIndex! < foundPatients.length)
                  Card(
                    elevation: 2,
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Patient: $_selectedPatientName',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'ID Number: ${foundPatients[selectedPatientIndex!]['IDNUMBER'] ?? ''}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                selectedPatientIndex = null;
                                _selectedPatientId = null;
                                _selectedPatientName = null;
                                _selectedPatientIdNumber = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // Clinical Procedure Form (only show if patient is selected)
                if (_selectedPatientId != null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clinical Procedure Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date of Operation
                          GestureDetector(
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateOfOperationController.text = picked.toIso8601String().split('T')[0];
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateOfOperationController,
                                decoration: const InputDecoration(
                                  labelText: 'Date of Operation *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Type of Operation
                          TextFormField(
                            controller: _typeOfOperationController,
                            decoration: const InputDecoration(
                              labelText: 'Type of Operation *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Tooth Number
                          TextFormField(
                            controller: _toothNoController,
                            decoration: const InputDecoration(
                              labelText: 'Tooth Number *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Clinic Name Dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Clinic Name *',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _selectedClinic,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Select Clinic'),
                              ),
                              ..._clinics.map((clinic) => DropdownMenuItem<String>(
                                value: clinic,
                                child: Text('Clinic $clinic'),
                              )),
                            ],
                            onChanged: (val) => setState(() => _selectedClinic = val),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Student Search Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Responsible Student: *'),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _studentSearchController,
                                              decoration: InputDecoration(
                                                labelText: 'Search student (name or university ID)',
                                                prefixIcon: const Icon(Icons.school),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onChanged: (_) => searchStudent(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: isSearchingStudent
                                                ? const CircularProgressIndicator()
                                                : const Icon(Icons.search),
                                            onPressed: isSearchingStudent ? null : searchStudent,
                                          ),
                                        ],
                                      ),
                                      if (studentError != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            studentError!,
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Student Search Results
                              if (foundStudents.isNotEmpty && selectedStudentIndex == null)
                                Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Student Search Results (${foundStudents.length})',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...foundStudents.asMap().entries.map((entry) {
                                          final i = entry.key;
                                          final student = entry.value;
                                          
                                          final fullName = student['fullName']?.toString() ?? 'Student without name';
                                          final universityId = student['universityId']?.toString() ?? student['studentUniversityId']?.toString() ?? 'N/A';
                                          
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            color: selectedStudentIndex == i ? Colors.blue[50] : null,
                                            child: ListTile(
                                              leading: const Icon(Icons.school),
                                              title: Text(
                                                fullName,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('University ID: $universityId'),
                                                  if (student['idNumber'] != null && student['idNumber'].toString().isNotEmpty)
                                                    Text('ID Number: ${student['idNumber']}'),
                                                ],
                                              ),
                                              trailing: selectedStudentIndex == i
                                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                                              onTap: () {
                                                setState(() {
                                                  selectedStudentIndex = i;
                                                  _selectedStudentName = fullName;
                                                });
                                                FocusScope.of(context).unfocus();
                                              },
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),

                              // Selected Student
                              if (selectedStudentIndex != null && foundStudents.isNotEmpty && selectedStudentIndex! < foundStudents.length)
                                Card(
                                  elevation: 2,
                                  color: Colors.blue[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Selected Student: $_selectedStudentName',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                'University ID: ${foundStudents[selectedStudentIndex!]['universityId'] ?? foundStudents[selectedStudentIndex!]['studentUniversityId'] ?? ''}',
                                                style: TextStyle(color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              selectedStudentIndex = null;
                                              _selectedStudentName = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Supervisor Name (Auto-filled)
                          TextFormField(
                            controller: _supervisorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Supervisor Name *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.person),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),

                          // Loading/Warning Messages
                          if (_currentDoctorName == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  CircularProgressIndicator(strokeWidth: 2),
                                  SizedBox(width: 12),
                                  Text('Loading supervisor data...'),
                                ],
                              ),
                            )
                          else if (_currentDoctorName == 'Unknown Supervisor')
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Supervisor not recognized', style: TextStyle(color: Colors.orange)),
                                ],
                              ),
                            ),

                          // Date of Second Visit (Optional)
                          GestureDetector(
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateOfSecondVisitController.text = picked.toIso8601String().split('T')[0];
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateOfSecondVisitController,
                                decoration: const InputDecoration(
                                  labelText: 'Date of Second Visit (Optional)',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _currentDoctorName == null || 
                                       _currentDoctorName!.isEmpty || 
                                       _currentDoctorName == 'Unknown Supervisor' ||
                                       _selectedStudentName == null
                                  ? null
                                  : _submitForm,
                              child: _currentDoctorName == null || 
                                     _currentDoctorName!.isEmpty || 
                                     _currentDoctorName == 'Unknown Supervisor' ||
                                     _selectedStudentName == null
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        SizedBox(width: 8),
                                        Text('Loading required data...', style: TextStyle(fontSize: 16, color: Colors.white)),
                                      ],
                                    )
                                  : const Text('Submit Form', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}