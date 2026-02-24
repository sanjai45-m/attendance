import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/attendance_provider.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/services/excel_service.dart';
import 'package:attendance/widgets/attendance_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ExcelService _excelService = ExcelService();
  DateTimeRange? _dateRange;
  String? _selectedEmployeeUid;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Default: last 7 days
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadEmployees();
      _loadReport();
    });
  }

  void _loadReport() {
    if (_dateRange == null) return;
    context.read<AttendanceProvider>().loadReportData(
          startDate: AppDateUtils.toDateString(_dateRange!.start),
          endDate: AppDateUtils.toDateString(_dateRange!.end),
          uid: _selectedEmployeeUid,
        );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: AppStrings.exportExcel,
            onPressed: attendanceProvider.reportData.isEmpty || _isExporting
                ? null
                : _exportExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.cardBg,
            child: Column(
              children: [
                // Date range
                GestureDetector(
                  onTap: () => _pickDateRange(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dateRange != null
                                ? '${AppDateUtils.toDisplayDate(_dateRange!.start)} — ${AppDateUtils.toDisplayDate(_dateRange!.end)}'
                                : 'Select date range',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Employee filter
                DropdownButtonFormField<String?>(
                  initialValue: _selectedEmployeeUid,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Employee',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.primary, size: 20),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  dropdownColor: AppColors.surfaceBg,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Employees'),
                    ),
                    ...userProvider.employees.map(
                      (e) => DropdownMenuItem<String?>(
                        value: e.uid,
                        child: Text('${e.name} (${e.employeeId})'),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedEmployeeUid = val);
                    _loadReport();
                  },
                ),
                const SizedBox(height: 14),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadReport,
                    icon: const Icon(Icons.filter_list_rounded, size: 18),
                    label: const Text('Apply Filters'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results count
          if (attendanceProvider.reportData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${attendanceProvider.reportData.length} records found',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  if (_isExporting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),

          // Report data
          Expanded(
            child: attendanceProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : attendanceProvider.reportData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description_outlined,
                                size: 56,
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 10),
                            const Text(
                              'No records found',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Adjust your filters and try again',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: attendanceProvider.reportData.length,
                        itemBuilder: (context, index) {
                          return AttendanceCard(
                            attendance: attendanceProvider.reportData[index],
                            showEmployeeName: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
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
      setState(() => _dateRange = picked);
      _loadReport();
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);

    final reportData = context.read<AttendanceProvider>().reportData;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final filePath = await _excelService.generateReport(reportData);

      if (mounted) {
        setState(() => _isExporting = false);

        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.cardBg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 48),
                const SizedBox(height: 14),
                const Text(
                  AppStrings.reportExported,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _excelService.openFile(filePath);
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _excelService.shareFile(filePath);
                        },
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
