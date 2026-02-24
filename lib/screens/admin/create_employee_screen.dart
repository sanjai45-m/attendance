import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/core/utils/validators.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/widgets/custom_text_field.dart';
import 'package:attendance/widgets/loading_overlay.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'employee';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createEmployee),
      ),
      body: LoadingOverlay(
        isLoading: authProvider.isLoading,
        message: 'Creating employee...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Employee Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fill in the details to create a new employee account.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                CustomTextField(
                  controller: _nameController,
                  label: AppStrings.name,
                  prefixIcon: Icons.person_outlined,
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: 'Minimum 8 characters',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  label: AppStrings.phone,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _employeeIdController,
                  label: AppStrings.employeeId,
                  hint: 'e.g. EMP-001',
                  prefixIcon: Icons.badge_outlined,
                  validator: Validators.employeeId,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _departmentController,
                  label: AppStrings.department,
                  hint: 'e.g. Engineering',
                  prefixIcon: Icons.business_outlined,
                  validator: (v) => Validators.required(v, 'Department'),
                ),
                const SizedBox(height: 16),

                // Role dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: AppStrings.role,
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  dropdownColor: AppColors.surfaceBg,
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text('Employee'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedRole = val!);
                  },
                ),
                const SizedBox(height: 10),

                // Error
                if (authProvider.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      authProvider.error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed:
                        authProvider.isLoading ? null : _handleCreate,
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text(AppStrings.createEmployee),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final result = await auth.createEmployee(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      employeeId: _employeeIdController.text.trim(),
      department: _departmentController.text.trim(),
      role: _selectedRole,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.employeeCreated),
          backgroundColor: AppColors.success,
        ),
      );
      // Clear form
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _employeeIdController.clear();
      _departmentController.clear();
    }
  }
}
