import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/providers/attendance_provider.dart';
import 'package:attendance/providers/settings_provider.dart';

class PunchScreen extends StatefulWidget {
  const PunchScreen({super.key});

  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.uid != null) {
        context.read<AttendanceProvider>().loadTodayAttendance(auth.uid!);
        context.read<SettingsProvider>().loadSettings();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final settings = context.watch<SettingsProvider>();
    final today = attendance.todayAttendance;

    final canPunchIn = attendance.canPunchIn;
    final canPunchOut = attendance.canPunchOut;
    final isComplete = today?.isComplete ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punch In / Out'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Current time
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, _) {
                  return Text(
                    AppDateUtils.toTimeString(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                AppDateUtils.toDisplayDate(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 48),

              // Punch Button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isComplete ? 1.0 : _pulseAnimation.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: attendance.isPunching || isComplete
                      ? null
                      : () => canPunchIn
                          ? _handlePunchIn(auth, settings)
                          : canPunchOut
                              ? _handlePunchOut(auth, settings)
                              : null,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isComplete
                          ? const LinearGradient(
                              colors: [AppColors.success, Color(0xFF00C853)],
                            )
                          : canPunchIn
                              ? AppColors.primaryGradient
                              : const LinearGradient(
                                  colors: [AppColors.error, Color(0xFFFF1744)],
                                ),
                      boxShadow: [
                        BoxShadow(
                          color: (isComplete
                                  ? AppColors.success
                                  : canPunchIn
                                      ? AppColors.primary
                                      : AppColors.error)
                              .withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: attendance.isPunching
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 3,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isComplete
                                      ? Icons.check_circle_rounded
                                      : canPunchIn
                                          ? Icons.fingerprint_rounded
                                          : Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 56,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isComplete
                                      ? 'Done'
                                      : canPunchIn
                                          ? AppStrings.punchIn
                                          : AppStrings.punchOut,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Today's record
              if (today != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoColumn(
                        'Punch In',
                        today.punchIn != null
                            ? AppDateUtils.toTimeString(today.punchIn!)
                            : '--',
                        AppColors.success,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      _infoColumn(
                        'Punch Out',
                        today.punchOut != null
                            ? AppDateUtils.toTimeString(today.punchOut!)
                            : '--',
                        AppColors.error,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      _infoColumn(
                        'Hours',
                        today.totalHoursFormatted,
                        AppColors.primary,
                      ),
                    ],
                  ),
                ),

              // Error
              if (attendance.error != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    attendance.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePunchIn(
      AuthProvider auth, SettingsProvider settings) async {
    final user = auth.currentUser;
    if (user == null) return;

    final attendanceProv = context.read<AttendanceProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await attendanceProv.punchIn(
      uid: user.uid,
      employeeId: user.employeeId,
      employeeName: user.name,
      settings: settings.settings,
    );

    if (success && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.punchInSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handlePunchOut(
      AuthProvider auth, SettingsProvider settings) async {
    final user = auth.currentUser;
    if (user == null) return;

    final attendanceProv = context.read<AttendanceProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await attendanceProv.punchOut(
      uid: user.uid,
      employeeId: user.employeeId,
      employeeName: user.name,
      settings: settings.settings,
    );

    if (success && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.punchOutSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
