import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/providers/leave_provider.dart';
import 'package:attendance/widgets/loading_overlay.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  DateTime? _selectedDate;
  String _selectedType = 'Sick';
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final leaveProvider = context.read<LeaveProvider>();

    final success = await leaveProvider.submitLeaveRequest(
      uid: authProvider.currentUser!.uid,
      employeeId: authProvider.currentUser!.employeeId,
      employeeName: authProvider.currentUser!.name,
      date: AppDateUtils.toDateString(_selectedDate!),
      type: _selectedType,
      reason: _selectedType == 'Other' ? _reasonController.text.trim() : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leaveProvider.error ?? 'Failed to submit request'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = context.watch<LeaveProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Leave')),
      body: LoadingOverlay(
        isLoading: leaveProvider.isLoading,
        message: 'Submitting request...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select the date and type of leave you are requesting.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Date Picker
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : AppDateUtils.toDisplayDate(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Leave Type',
                    prefixIcon: Icon(
                      Icons.category_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  dropdownColor: AppColors.surfaceBg,
                  items: const [
                    DropdownMenuItem(value: 'Sick', child: Text('Sick Leave')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 16),

                // Reason Map (Only if 'Other' is selected)
                if (_selectedType == 'Other')
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason (Mandatory for "Other")',
                      alignLabelWithHint: true,
                    ),
                    validator: (val) {
                      if (_selectedType == 'Other' &&
                          (val == null || val.trim().isEmpty)) {
                        return 'Please provide a reason for taking leave.';
                      }
                      return null;
                    },
                  ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Submit Leave Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
