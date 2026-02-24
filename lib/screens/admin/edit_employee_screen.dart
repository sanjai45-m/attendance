import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/core/utils/validators.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/services/firestore_service.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/widgets/custom_text_field.dart';
import 'package:attendance/widgets/loading_overlay.dart';

class EditEmployeeScreen extends StatefulWidget {
  final String uid;

  const EditEmployeeScreen({super.key, required this.uid});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _employee;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    final user = await FirestoreService().getUser(widget.uid);
    if (user != null && mounted) {
      setState(() {
        _employee = user;
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _employeeIdController.text = user.employeeId;
        _departmentController.text = user.department;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editEmployee),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _employee == null
              ? const Center(
                  child: Text(
                    'Employee not found',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : LoadingOverlay(
                  isLoading: _isSaving,
                  message: 'Saving changes...',
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email (read-only)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.email_outlined,
                                    color: AppColors.textMuted, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _employee!.email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _nameController,
                            label: AppStrings.name,
                            prefixIcon: Icons.person_outlined,
                            validator: (v) => Validators.required(v, 'Name'),
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
                            prefixIcon: Icons.badge_outlined,
                            validator: Validators.employeeId,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _departmentController,
                            label: AppStrings.department,
                            prefixIcon: Icons.business_outlined,
                            validator: (v) =>
                                Validators.required(v, 'Department'),
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _handleSave,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success =
        await context.read<UserProvider>().updateEmployee(widget.uid, {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'employeeId': _employeeIdController.text.trim(),
      'department': _departmentController.text.trim(),
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.employeeUpdated),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
