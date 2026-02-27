import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/models/leave_request_model.dart';
import 'package:attendance/providers/leave_provider.dart';
import 'package:attendance/widgets/loading_overlay.dart';

class AdminLeaveRequestsScreen extends StatefulWidget {
  const AdminLeaveRequestsScreen({super.key});

  @override
  State<AdminLeaveRequestsScreen> createState() =>
      _AdminLeaveRequestsScreenState();
}

class _AdminLeaveRequestsScreenState extends State<AdminLeaveRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().startStreamingAllRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateStatus(
    LeaveRequestModel request,
    String status,
  ) async {
    final leaveProv = context.read<LeaveProvider>();
    final success = await leaveProv.updateRequestStatus(request, status);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request $status successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leaveProv.error ?? 'Failed to update request'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveProv = context.watch<LeaveProvider>();
    final allRequests = leaveProv.allRequests;

    final pending = allRequests.where((r) => r.status == 'Pending').toList();
    final approved = allRequests.where((r) => r.status == 'Approved').toList();
    final rejected = allRequests.where((r) => r.status == 'Rejected').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: leaveProv.isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(pending, showActions: true),
            _buildList(approved, showActions: false),
            _buildList(rejected, showActions: false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<LeaveRequestModel> requests, {
    required bool showActions,
  }) {
    if (requests.isEmpty) {
      return const Center(
        child: Text(
          'No requests found.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Card(
          color: AppColors.surfaceBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.employeeName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: req.status == 'Pending'
                            ? Colors.orange.withValues(alpha: 0.2)
                            : req.status == 'Approved'
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.status,
                        style: TextStyle(
                          color: req.status == 'Pending'
                              ? Colors.orange
                              : req.status == 'Approved'
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${req.date}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                Text(
                  'Type: ${req.type}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                if (req.reason != null && req.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reason: ${req.reason}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Requested on: ${AppDateUtils.toDisplayDate(req.createdAt)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleUpdateStatus(req, 'Rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleUpdateStatus(req, 'Approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
