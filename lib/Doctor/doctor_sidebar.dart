import 'package:flutter/material.dart';
import 'clinical_procedures_form.dart';
import 'dart:convert';
import '../Shared/waiting_list_page.dart';
import '../Doctor/examined_patients_page.dart';
import '../dashboard/doctor_dashboard.dart';
import 'prescription_page.dart';
import 'doctor_xray_request_page.dart';
import '../Doctor/assign_patients_to_student_page.dart';

class DoctorSidebar extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  final String? userName;
  final String? userImageUrl;
  final VoidCallback? onLogout;
  final BuildContext parentContext;
  final bool collapsed;
  final String Function(BuildContext, String) translate;
  final String doctorUid;
  final List<String> allowedFeatures;

  const DoctorSidebar({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.userName,
    this.userImageUrl,
    this.onLogout,
    required this.parentContext,
    this.collapsed = false,
    required this.translate,
    required this.doctorUid,
    required this.allowedFeatures, required String userRole,
  });

  @override
  Widget build(BuildContext context) {
  final isArabic = Localizations.localeOf(parentContext).languageCode == 'ar';

  // Define all possible features (بدون dashboard)
  final allFeatureBoxes = [
    {
      'key': 'waiting_list',
      'icon': Icons.list_alt,
      'title': translate(parentContext, 'waiting_list'),
      'onTap': () {
        Navigator.pop(context);
        Navigator.push(
          parentContext,
          MaterialPageRoute(builder: (_) => const WaitingListPage(userRole: 'doctor')),
        );
      }
    },
      {
        'key': 'clinical_procedures_form',
        'icon': Icons.medical_information,
        'title': isArabic ? 'نموذج الإجراءات السريرية' : 'Clinical Procedures Form',
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            parentContext,
            MaterialPageRoute(builder: (_) => ClinicalProceduresForm(uid: doctorUid)),
          );
        }
      },
    
    {
  'key': 'examined_patients',
  'icon': Icons.check_circle,
  'title': translate(parentContext, 'examined_patients'),
  'onTap': () {
    Navigator.pop(context);
    Navigator.push(
      parentContext,
      MaterialPageRoute(builder: (_) => DoctorExaminedPatientsPage(
        doctorName: userName,
        doctorImageUrl: userImageUrl,
        currentUserId: doctorUid,
        userAllowedFeatures: allowedFeatures,
      )),
    );
  }
},
      {
        'key': 'prescription',
        'icon': Icons.medical_services,
        'title': translate(parentContext, 'prescription'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            parentContext,
            MaterialPageRoute(builder: (_) => PrescriptionPage( uid: doctorUid)),
          );
        }
      },
      {
        'key': 'xray_request',
        'icon': Icons.camera_alt,
        'title': translate(parentContext, 'xray_request'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            parentContext,
            MaterialPageRoute(builder: (_) => const DoctorXrayRequestPage()),
          );
        }
      },
      {
        'key': 'assign_patients_to_students',
        'icon': Icons.assignment_ind,
        'title': translate(parentContext, 'assign_patients_to_students'),
        'onTap': () {
          Navigator.pop(context);
          Navigator.push(
            parentContext,
            MaterialPageRoute(builder: (_) => const AssignPatientsToStudentPage()),
          );
        }
      },
    ];


  // Filter features by allowedFeatures فقط (بدون dashboard)
  final Set<String> featuresSet = Set<String>.from(allowedFeatures);
  final sidebarFeatures = allFeatureBoxes.where((f) => featuresSet.contains(f['key'])).toList();

    double sidebarWidth = collapsed ? 60 : 260;
    if (MediaQuery.of(context).size.width < 700 && !collapsed) {
      sidebarWidth = 200;
    }

    return Drawer(
      child: Container(
        width: sidebarWidth,
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (userImageUrl != null && userImageUrl!.isNotEmpty)
                    userImageUrl!.startsWith('http') || userImageUrl!.startsWith('https')
                        ? CircleAvatar(
                            radius: collapsed ? 18 : 32,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(userImageUrl!),
                          )
                        : CircleAvatar(
                            radius: collapsed ? 18 : 32,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.memory(
                                base64Decode(userImageUrl!.replaceFirst('data:image/jpeg;base64,', '')),
                                width: collapsed ? 36 : 64,
                                height: collapsed ? 36 : 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                  else
                    CircleAvatar(
                      radius: collapsed ? 18 : 32,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: collapsed ? 18 : 32, color: accentColor),
                    ),
                  if (!collapsed) ...[
                    const SizedBox(height: 10),
                    Text(
                      userName ?? (isArabic ? 'دكتور' : 'Doctor'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isArabic ? 'دكتور' : 'Doctor',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            // زر الرئيسية الثابت
            _buildSidebarItem(
              context,
              icon: Icons.home,
              label: isArabic ? 'الرئيسية' : 'Dashboard',
              onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                parentContext,
                MaterialPageRoute(builder: (_) => const SupervisorDashboard()),
                (route) => false,
              );
              },
            ),
            // باقي العناصر حسب الصلاحيات
            for (final feature in sidebarFeatures)
              _buildSidebarItem(
                context,
                icon: feature['icon'] as IconData,
                label: feature['title'] as String,
                onTap: feature['onTap'] as VoidCallback,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? primaryColor),
      title: collapsed ? null : Text(label),
      onTap: onTap,
      contentPadding: collapsed ? const EdgeInsets.symmetric(horizontal: 12) : null,
      minLeadingWidth: 0,
      horizontalTitleGap: collapsed ? 0 : null,
    );
  }
}
