import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';
import 'package:sharoni/core/models/profile.dart';
import 'package:sharoni/core/services/notification_service.dart';
import 'package:sharoni/features/profile/presentation/settings_page.dart';
import 'package:sharoni/features/insights/presentation/medical_records_page.dart';
import 'package:sharoni/features/profile/presentation/notification_settings_page.dart';
import 'package:sharoni/features/profile/presentation/privacy_security_page.dart';
import 'package:sharoni/features/profile/presentation/help_support_page.dart';
import 'package:sharoni/features/profile/presentation/health_report_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  String? _selectedSex;
  String? _selectedBloodType;
  String? _selectedGenotype;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    _currentMedicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    super.dispose();
  }

  void _showEditProfile(Profile? profile) {
    _ageController.text = profile?.age ?? '';
    _heightController.text = profile?.height ?? '';
    _weightController.text = profile?.weight ?? '';
    _medicalConditionsController.text = profile?.medicalConditions ?? '';
    _allergiesController.text = profile?.allergies ?? '';
    _currentMedicationsController.text = profile?.currentMedications ?? '';
    _emergencyNameController.text = profile?.emergencyContactName ?? '';
    _emergencyPhoneController.text = profile?.emergencyContactPhone ?? '';
    _emergencyRelationshipController.text = profile?.emergencyContactRelationship ?? '';
    _selectedSex = profile?.sex;
    _selectedBloodType = profile?.bloodType;
    _selectedGenotype = profile?.genotype;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E293B)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Edit Health Profile',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This information is optional and helps improve AI insights.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                
                const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_ageController, 'Age', Icons.cake)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSex,
                        decoration: InputDecoration(
                          labelText: 'Sex at Birth',
                          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: ['Male', 'Female', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setModalState(() => _selectedSex = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_heightController, profile?.measurementUnit == 'metric' ? 'Height (cm)' : 'Height (ft)', Icons.height)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_weightController, profile?.measurementUnit == 'metric' ? 'Weight (kg)' : 'Weight (lbs)', Icons.monitor_weight_outlined)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        decoration: InputDecoration(
                          labelText: 'Blood Type',
                          prefixIcon: const Icon(Icons.bloodtype, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setModalState(() => _selectedBloodType = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGenotype,
                        decoration: InputDecoration(
                          labelText: 'Genotype',
                          prefixIcon: const Icon(Icons.biotech, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: ['AA', 'AS', 'AC', 'SS', 'SC', 'CC'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setModalState(() => _selectedGenotype = val),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text('Medical Background', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildTextField(_medicalConditionsController, 'Known Medical Conditions', Icons.history_edu, maxLines: 2),
                const SizedBox(height: 12),
                _buildTextField(_allergiesController, 'Allergies', Icons.warning_amber_outlined, maxLines: 2),
                const SizedBox(height: 12),
                _buildTextField(_currentMedicationsController, 'Current Medications', Icons.medication_outlined, maxLines: 2),
                
                const SizedBox(height: 24),
                const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildTextField(_emergencyNameController, 'Contact Name', Icons.person_outline),
                const SizedBox(height: 12),
                _buildTextField(_emergencyPhoneController, 'Phone Number', Icons.phone_outlined),
                const SizedBox(height: 12),
                _buildTextField(_emergencyRelationshipController, 'Relationship', Icons.family_restroom_outlined),
                

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(profileControllerProvider.notifier).updateProfile(
                        age: _ageController.text,
                        height: _heightController.text,
                        weight: _weightController.text,
                        sex: _selectedSex,
                        bloodType: _selectedBloodType,
                        genotype: _selectedGenotype,
                        medicalConditions: _medicalConditionsController.text,
                        allergies: _allergiesController.text,
                        currentMedications: _currentMedicationsController.text,
                        emergencyContactName: _emergencyNameController.text,
                        emergencyContactPhone: _emergencyPhoneController.text,
                        emergencyContactRelationship: _emergencyRelationshipController.text,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Profile Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and will delete all your health data, '
          'medication logs, and profile information. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authControllerProvider.notifier).deleteAccount();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB), // Subtle off-white from image
      body: profileAsync.when(
        data: (profile) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your health identity',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 26, color: AppTheme.primaryColor),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showEditProfile(profile),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User Info Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (user?.email != null && user!.email!.isNotEmpty)
                                ? user.email!.substring(0, 2).toUpperCase()
                                : 'SJ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email?.split('@').first ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'sarah.j@email.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F6F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Premium Member',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Statistics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      icon: Icons.favorite,
                      iconColor: Colors.white,
                      iconBgColor: const Color(0xFFFF4B72),
                      value: '24',
                      label: 'Symptoms Logged',
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.link, // or pill icon if available
                      iconColor: Colors.white,
                      iconBgColor: const Color(0xFF6B7BFF),
                      value: '4',
                      label: 'Medications',
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.calendar_month,
                      iconColor: Colors.white,
                      iconBgColor: const Color(0xFF00BFA6),
                      value: '12',
                      label: 'Days Active',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Health Information Grid Card
                _buildSectionCard(
                  title: 'Health Information',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildGridItem('Age', (profile?.age?.isNotEmpty == true) ? '${profile!.age} years' : 'Not set')),
                          Expanded(child: _buildGridItem('Blood Type', profile?.bloodType ?? 'Not set')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildGridItem('Genotype', profile?.genotype ?? 'Not set')),
                          Expanded(child: _buildGridItem('Height', (profile?.height?.isNotEmpty == true) 
                              ? '${profile!.height} ${profile.measurementUnit == 'metric' ? 'cm' : 'ft'}' 
                              : 'Not set')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGridItem('Weight', (profile?.weight?.isNotEmpty == true) 
                          ? '${profile!.weight} ${profile.measurementUnit == 'metric' ? 'kg' : 'lbs'}' 
                          : 'Not set'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Allergies Card
                _buildSectionCard(
                  title: 'Allergies',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: (profile?.allergies?.isNotEmpty == true
                            ? profile!.allergies!.split(',')
                            : ['None reported'])
                        .map((allergy) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFD6D6)),
                              ),
                              child: Text(
                                allergy.trim(),
                                style: const TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionCard(
                  title: 'Emergency Contact',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile?.emergencyContactName == null || profile!.emergencyContactName!.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.contact_phone_outlined, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'No emergency contact set',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => _showEditProfile(profile),
                                child: const Text('Set up Emergency Contact'),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _buildGridItem('Name', profile!.emergencyContactName!),
                        const SizedBox(height: 16),
                        _buildGridItem('Phone', profile.emergencyContactPhone ?? 'Not set'),
                        const SizedBox(height: 16),
                        _buildGridItem('Relationship', profile.emergencyContactRelationship ?? 'Not set'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // Settings List Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF4A6DFB),
                        iconBgColor: const Color(0xFFEBF0FF),
                        title: 'Account Settings',
                        isFirst: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.article_outlined,
                        iconColor: const Color(0xFF00BFA6),
                        iconBgColor: const Color(0xFFE6FAF6),
                        title: 'Medical Records',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MedicalRecordsPage()),
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.summarize_outlined,
                        iconColor: const Color(0xFF1A2340),
                        iconBgColor: const Color(0xFFE8EBF5),
                        title: "Doctor's Health Report",
                        subtitle: 'Full report for your doctor or emergency contact',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HealthReportPage()),
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.notifications_none,
                        iconColor: const Color(0xFF9462FF),
                        iconBgColor: const Color(0xFFF3EDFF),
                        title: 'Notifications',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFFFFB020),
                        iconBgColor: const Color(0xFFFFF7E6),
                        title: 'Privacy & Security',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacySecurityPage()),
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.notifications_active_outlined,
                        iconColor: const Color(0xFFFFB038),
                        iconBgColor: const Color(0xFFFFF7E6),
                        title: 'Test Notification System',
                        onTap: () => NotificationService().showWarning('System Test', 'Your health alert system is active and functional.'),
                      ),
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        iconColor: const Color(0xFFFF4B72),
                        iconBgColor: const Color(0xFFFFEAEE),
                        title: 'Help & Support',
                        isLast: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign Out Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton.icon(
                      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout, color: Colors.grey),
                      label: const Text('Sign Out', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildGridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 16 : 0),
            topRight: Radius.circular(isFirst ? 16 : 0),
            bottomLeft: Radius.circular(isLast ? 16 : 0),
            bottomRight: Radius.circular(isLast ? 16 : 0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (subtitle != null) ...[  
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Divider(height: 1, color: Colors.grey[100]),
          ),
      ],
    );
  }

}
