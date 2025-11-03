// ignore_for_file: duplicate_ignore, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/services.dart';
import 'admin_sidebar.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AddDentalStudentPage extends StatefulWidget {
  final String? userName;
  final String? userImageUrl;
  final String Function(BuildContext, String)? translate;
  final VoidCallback? onLogout;
  final List<Map<String, dynamic>> allUsers;

  const AddDentalStudentPage({
    super.key,
    this.userName,
    this.userImageUrl,
    this.translate,
    this.onLogout,
    required this.allUsers,
  });

  @override
  State<AddDentalStudentPage> createState() => _AddDentalStudentPageState();
}

class _AddDentalStudentPageState extends State<AddDentalStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _studentIdController = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool isSidebarOpen = false;
  bool showSidebarButton = true;

  final Color primaryColor = const Color(0xFF2A7A94);
  final Color accentColor = const Color(0xFF4AB8D8);
  final String _apiBaseUrl = 'http://localhost:3000';

  // ترجمة محسنة
  final Map<String, Map<String, String>> _translations = {
    'admin_dashboard': {'ar': 'لوحة الإدارة', 'en': 'Admin Dashboard'},
    'manage_users': {'ar': 'إدارة المستخدمين', 'en': 'Manage Users'},
    'add_user': {'ar': 'إضافة مستخدم', 'en': 'Add User'},
    'add_user_student': {'ar': 'إضافة طالب طب أسنان', 'en': 'Add Dental Student'},
    'change_permissions': {'ar': 'تغيير الصلاحيات', 'en': 'Change Permissions'},
    'admin': {'ar': 'مدير النظام', 'en': 'System Admin'},
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
    'logout': {'ar': 'تسجيل الخروج', 'en': 'Logout'},
    
    // حقول النموذج
    'first_name': {'ar': 'الاسم الأول', 'en': 'First Name'},
    'father_name': {'ar': 'اسم الأب', 'en': 'Father Name'},
    'grandfather_name': {'ar': 'اسم الجد', 'en': 'Grandfather Name'},
    'family_name': {'ar': 'اسم العائلة', 'en': 'Family Name'},
    'username': {'ar': 'اسم المستخدم', 'en': 'Username'},
    'birth_date': {'ar': 'تاريخ الميلاد', 'en': 'Birth Date'},
    'select_date': {'ar': 'اختر التاريخ', 'en': 'Select date'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'phone_number': {'ar': 'رقم الهاتف', 'en': 'Phone Number'},
    'address': {'ar': 'العنوان', 'en': 'Address'},
    'id_number': {'ar': 'رقم الهوية', 'en': 'ID Number'},
    'student_id': {'ar': 'رقم الطالب', 'en': 'Student ID'},
    'personal_info': {'ar': 'المعلومات الشخصية', 'en': 'Personal Information'},
    'account_info': {'ar': 'معلومات الحساب', 'en': 'Account Information'},
    'password': {'ar': 'كلمة المرور', 'en': 'Password'},
    'confirm_password': {'ar': 'تأكيد كلمة المرور', 'en': 'Confirm Password'},
    'add': {'ar': 'إضافة', 'en': 'Add'},
    
    // رسائل التحقق
    'required_field': {'ar': 'هذا الحقل مطلوب', 'en': 'This field is required'},
    'phone_10_digits': {'ar': 'يجب أن يكون رقم الهاتف 10 أرقام', 'en': 'Phone must be 10 digits'},
    'id_9_digits': {'ar': 'يجب أن يكون رقم الهوية 9 أرقام', 'en': 'ID must be 9 digits'},
    'student_id_9_digits': {'ar': 'يجب أن يكون رقم الطالب 9 أرقام', 'en': 'Student ID must be 9 digits'},
    'password_6_chars': {'ar': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل', 'en': 'Password must be at least 6 characters'},
    'passwords_not_match': {'ar': 'كلمتا المرور غير متطابقتين', 'en': 'Passwords do not match'},
    'select_gender': {'ar': 'يرجى اختيار الجنس', 'en': 'Please select gender'},
    'student_added_success': {'ar': 'تمت إضافة الطالب بنجاح', 'en': 'Student added successfully'},
    'username_taken': {'ar': 'اسم المستخدم مستخدم بالفعل', 'en': 'Username already taken'},
    'email_in_use': {'ar': 'البريد الإلكتروني مستخدم بالفعل', 'en': 'Email already in use'},
    'weak_password': {'ar': 'كلمة المرور ضعيفة', 'en': 'Password must be at least 6 characters'},
    'error_adding_student': {'ar': 'حدث خطأ أثناء إضافة الطالب', 'en': 'Error adding student'},
    'numbers_only': {'ar': 'يجب إدخال أرقام فقط', 'en': 'Numbers only'},
    'english_numbers_only': {'ar': 'يرجى تحويل الكيبورد للأرقام الإنجليزية', 'en': 'Please switch keyboard to English numbers'},
  };

  String _tr(BuildContext context, String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.currentLocale.languageCode] ?? key;
  }

  // فلتر للأرقام فقط
  final FilteringTextInputFormatter _numbersOnlyFormatter = 
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  // دالة للتحقق من أن الإدخال يحتوي على أرقام إنجليزية فقط
  String? _validateEnglishNumbers(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // التحقق من وجود أي أحرف عربية أو غير إنجليزية
    if (RegExp(r'[٠-٩]').hasMatch(value) || 
        RegExp(r'[۰-۹]').hasMatch(value) ||
        RegExp(r'[^\x00-\x7F]').hasMatch(value) && !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return _tr(context, 'english_numbers_only');
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRtl = languageProvider.currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeScreen = constraints.maxWidth >= 900;
          
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(_tr(context, 'add_user_student')),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: _buildAppBarLeading(isLargeScreen, isRtl),
            ),
            body: Row(
              children: [
                if (isLargeScreen && isSidebarOpen)
                  _buildSidebar(isRtl),
                Expanded(
                  child: Stack(
                    children: [
                      _buildFormContent(),
                      if (!isLargeScreen && isSidebarOpen)
                        _buildMobileSidebarOverlay(isRtl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _buildAppBarLeading(bool isLargeScreen, bool isRtl) {
    if (isLargeScreen) {
      return showSidebarButton && !isSidebarOpen
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                setState(() {
                  isSidebarOpen = true;
                  showSidebarButton = false;
                });
              },
            )
          : null;
    } else {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          setState(() {
            isSidebarOpen = !isSidebarOpen;
          });
        },
      );
    }
  }

  Widget _buildSidebar(bool isRtl) {
    return Align(
      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: 260,
        child: Stack(
          children: [
            AdminSidebar(
              primaryColor: primaryColor,
              accentColor: accentColor,
              userName: widget.userName,
              userImageUrl: widget.userImageUrl,
              onLogout: widget.onLogout,
              parentContext: context,
              translate: _tr,
              allUsers: widget.allUsers, userRole: 'admin',
            ),
            Positioned(
              top: 8,
              right: isRtl ? null : 0,
              left: isRtl ? 0 : null,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    isSidebarOpen = false;
                    showSidebarButton = true;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSidebarOverlay(bool isRtl) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isSidebarOpen = false;
          });
        },
        child: Container(
          color: Colors.black.withAlpha(77),
          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: 260,
              height: double.infinity,
              child: Material(
                elevation: 8,
                child: Stack(
                  children: [
                    AdminSidebar(
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      userName: widget.userName,
                      userImageUrl: widget.userImageUrl,
                      onLogout: widget.onLogout,
                      parentContext: context,
                      translate: _tr,
                      allUsers: widget.allUsers,
                      userRole: 'admin',
                    ),
                    Positioned(
                      top: 8,
                      right: isRtl ? null : 0,
                      left: isRtl ? 0 : null,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            isSidebarOpen = false;
                          });
                        },
                      ),
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

  Widget _buildFormContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildPersonalInfoSection(),
              const SizedBox(height: 20),
              _buildAccountInfoSection(),
              const SizedBox(height: 30),
              _buildAddButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            _tr(context, 'personal_info'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildNameFields(),
          const SizedBox(height: 15),
          _buildAddressAndBirthDate(), // تغيير: العنوان وتاريخ الميلاد معاً
          const SizedBox(height: 15),
          _buildUsernameField(), // تغيير: اسم المستخدم منفرد
          const SizedBox(height: 15),
          _buildGenderSelection(),
          const SizedBox(height: 15),
          _buildPhoneField(),
          const SizedBox(height: 15),
          _buildIdNumberField(),
          const SizedBox(height: 15),
          _buildStudentIdField(),
        ],
      ),
    );
  }

  Widget _buildNameFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextFormField(
                controller: _firstNameController,
                labelText: _tr(context, 'first_name'),
                prefixIcon: Icon(Icons.person, color: accentColor),
                validator: (value) => _validateRequired(value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextFormField(
                controller: _fatherNameController,
                labelText: _tr(context, 'father_name'),
                prefixIcon: Icon(Icons.person, color: accentColor),
                validator: (value) => _validateRequired(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildTextFormField(
                controller: _grandfatherNameController,
                labelText: _tr(context, 'grandfather_name'),
                prefixIcon: Icon(Icons.person, color: accentColor),
                validator: (value) => _validateRequired(value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextFormField(
                controller: _familyNameController,
                labelText: _tr(context, 'family_name'),
                prefixIcon: Icon(Icons.person, color: accentColor),
                validator: (value) => _validateRequired(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // تغيير: دالة جديدة تجمع بين العنوان وتاريخ الميلاد
  Widget _buildAddressAndBirthDate() {
    return Row(
      children: [
        Expanded(
          child: _buildTextFormField(
            controller: _addressController,
            labelText: _tr(context, 'address'),
            prefixIcon: Icon(Icons.location_on, color: accentColor),
            validator: (value) => _validateRequired(value),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBirthDateField(),
        ),
      ],
    );
  }

  // تغيير: دالة منفصلة لاسم المستخدم
  Widget _buildUsernameField() {
    return _buildTextFormField(
      controller: _usernameController,
      labelText: _tr(context, 'username'),
      prefixIcon: Icon(Icons.person_pin, color: accentColor),
      validator: (value) => _validateRequired(value),
    );
  }

  Widget _buildBirthDateField() {
    return InkWell(
      onTap: _selectBirthDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _tr(context, 'birth_date'),
          labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
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
              ? _tr(context, 'select_date')
              : DateFormat('dd/MM/yyyy').format(_birthDate!),
          style: TextStyle(
            fontSize: 16,
            color: _birthDate == null ? Colors.grey[600] : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _tr(context, 'gender'),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(_tr(context, 'male')),
                value: 'male',
                groupValue: _gender,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(_tr(context, 'female')),
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

  Widget _buildPhoneField() {
    return _buildTextFormField(
      controller: _phoneController,
      labelText: _tr(context, 'phone_number'),
      keyboardType: TextInputType.phone,
      maxLength: 10,
      prefixIcon: Icon(Icons.phone, color: accentColor),
      inputFormatters: [_numbersOnlyFormatter],
      validator: (value) {
        if (value == null || value.isEmpty) return _tr(context, 'required_field');
        if (value.length < 10) return _tr(context, 'phone_10_digits');
        if (!RegExp(r'^[0-9]+$').hasMatch(value)) return _tr(context, 'numbers_only');
        
        // التحقق من الأرقام الإنجليزية
        final englishNumbersError = _validateEnglishNumbers(value);
        if (englishNumbersError != null) return englishNumbersError;
        
        return null;
      },
    );
  }

  // تم نقل _buildAddressField إلى _buildAddressAndBirthDate()

  Widget _buildIdNumberField() {
    return _buildTextFormField(
      controller: _idNumberController,
      labelText: _tr(context, 'id_number'),
      keyboardType: TextInputType.number,
      maxLength: 9,
      prefixIcon: Icon(Icons.credit_card, color: accentColor),
      inputFormatters: [_numbersOnlyFormatter],
      validator: (value) {
        if (value == null || value.isEmpty) return _tr(context, 'required_field');
        if (value.length < 9) return _tr(context, 'id_9_digits');
        if (!RegExp(r'^[0-9]+$').hasMatch(value)) return _tr(context, 'numbers_only');
        
        // التحقق من الأرقام الإنجليزية
        final englishNumbersError = _validateEnglishNumbers(value);
        if (englishNumbersError != null) return englishNumbersError;
        
        return null;
      },
    );
  }

  Widget _buildStudentIdField() {
    return _buildTextFormField(
      controller: _studentIdController,
      labelText: _tr(context, 'student_id'),
      keyboardType: TextInputType.number,
      maxLength: 9,
      prefixIcon: Icon(Icons.school, color: accentColor),
      inputFormatters: [_numbersOnlyFormatter],
      validator: (value) {
        if (value == null || value.isEmpty) return _tr(context, 'required_field');
        if (value.length < 9) return _tr(context, 'student_id_9_digits');
        if (!RegExp(r'^[0-9]+$').hasMatch(value)) return _tr(context, 'numbers_only');
        
        // التحقق من الأرقام الإنجليزية
        final englishNumbersError = _validateEnglishNumbers(value);
        if (englishNumbersError != null) return englishNumbersError;
        
        return null;
      },
    );
  }

  Widget _buildAccountInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            _tr(context, 'account_info'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 15),
          _buildConfirmPasswordField(),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return _buildTextFormField(
      controller: _passwordController,
      labelText: _tr(context, 'password'),
      obscureText: !_showPassword,
      prefixIcon: Icon(Icons.lock, color: accentColor),
      suffixIcon: IconButton(
        icon: Icon(
          _showPassword ? Icons.visibility : Icons.visibility_off,
          color: accentColor,
        ),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return _tr(context, 'required_field');
        if (value.length < 6) return _tr(context, 'password_6_chars');
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return _buildTextFormField(
      controller: _confirmPasswordController,
      labelText: _tr(context, 'confirm_password'),
      obscureText: !_showConfirmPassword,
      prefixIcon: Icon(Icons.lock_outline, color: accentColor),
      suffixIcon: IconButton(
        icon: Icon(
          _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
          color: accentColor,
        ),
        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return _tr(context, 'required_field');
        if (value != _passwordController.text) return _tr(context, 'passwords_not_match');
        return null;
      },
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addStudent,
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
                _tr(context, 'add_user_student'),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLength,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      enabled: enabled,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
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

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return _tr(context, 'required_field');
    }
    return null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  Future<bool> _isUsernameUnique(String username) async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/users?username=$username'));
      if (response.statusCode == 200) {
        final users = json.decode(response.body) as List;
        return users.isEmpty;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking username uniqueness: $e');
      return true;
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar(_tr(context, 'passwords_not_match'));
      return;
    }

    if (_gender == null) {
      _showSnackBar(_tr(context, 'select_gender'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isUnique = await _isUsernameUnique(_usernameController.text.trim());
      if (!isUnique) {
        _showSnackBar(_tr(context, 'username_taken'));
        setState(() => _isLoading = false);
        return;
      }

      // تحويل التاريخ إلى الصيغة dd/MM/yyyy
      String? birthDateFormatted;
      if (_birthDate != null) {
        birthDateFormatted = DateFormat('dd/MM/yyyy').format(_birthDate!);
      }

      final studentData = {
        // الحقول كما هي في قاعدة البيانات
        'USER_ID': _studentIdController.text.trim(),
        'FIRST_NAME': _firstNameController.text.trim(),
        'FATHER_NAME': _fatherNameController.text.trim(),
        'GRANDFATHER_NAME': _grandfatherNameController.text.trim(),
        'FAMILY_NAME': _familyNameController.text.trim(),
        'FULL_NAME': '${_firstNameController.text.trim()} ${_fatherNameController.text.trim()} ${_grandfatherNameController.text.trim()} ${_familyNameController.text.trim()}',
        'USERNAME': _usernameController.text.trim(),
        'ID_NUMBER': _idNumberController.text.trim(),
        'STUDENT_ID': _idNumberController.text.trim(),
        'BIRTH_DATE': birthDateFormatted, // الصيغة dd/MM/yyyy
        'GENDER': _gender,
        'ROLE': 'dental_student',
        'PHONE': _phoneController.text.trim(),
        'ADDRESS': _addressController.text.trim(),
        'EMAIL': '${_usernameController.text.trim()}@student.aaup.edu',
        'IMAGE': null,
        'IS_ACTIVE': 1,
        // 🔥 الحل: أرسل كلمة السر في حقل 'password' (بالحروف الصغيرة)
        'password': _passwordController.text.trim(),
      };


      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(studentData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar(_tr(context, 'student_added_success'));
        if (mounted) Navigator.of(context).pop();
      } else {
        _showSnackBar(_tr(context, 'error_adding_student'));
      }
    } catch (e) {
      _showSnackBar('${_tr(context, 'error_adding_student')}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _familyNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}