import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/providers/settings_provider.dart';
import 'package:attendance/widgets/loading_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSaving = false;

  TextEditingController? _startHourController;
  TextEditingController? _startMinuteController;
  TextEditingController? _endHourController;
  TextEditingController? _endMinuteController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initControllers();
    });
  }

  void _initControllers() {
    final settingsProv = context.read<SettingsProvider>();
    final startParts = settingsProv.settings.workStartTime.split(':');
    final endParts = settingsProv.settings.workEndTime.split(':');

    _startHourController = TextEditingController(
      text: startParts.isNotEmpty ? startParts[0] : '09',
    );
    _startMinuteController = TextEditingController(
      text: startParts.length > 1 ? startParts[1] : '00',
    );

    _endHourController = TextEditingController(
      text: endParts.isNotEmpty ? endParts[0] : '18',
    );
    _endMinuteController = TextEditingController(
      text: endParts.length > 1 ? endParts[1] : '00',
    );

    setState(() {}); // refresh after init
  }

  @override
  void dispose() {
    _startHourController?.dispose();
    _startMinuteController?.dispose();
    _endHourController?.dispose();
    _endMinuteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If controllers aren't initialized yet
    if (!mounted ||
        _startHourController == null ||
        _endHourController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LoadingOverlay(
        isLoading: _isSaving || settingsProv.isLoading,
        message: 'Saving settings...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Work Hours Tracker',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure the standard work times. Punch-outs after the end time will be recorded as overtime.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              _buildTimeInput(
                label: 'Work Start Time (24h)',
                hourController: _startHourController!,
                minuteController: _startMinuteController!,
                icon: Icons.wb_sunny_rounded,
              ),

              const SizedBox(height: 16),

              _buildTimeInput(
                label: 'Work End Time (24h)',
                hourController: _endHourController!,
                minuteController: _endMinuteController!,
                icon: Icons.nightlight_round,
              ),

              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Leave Reminders',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Receive a push notification every 5 hours if there are pending leave requests.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  activeColor: AppColors.primary,
                  value: settingsProv.settings.enableLeaveReminders,
                  onChanged: (val) async {
                    setState(() => _isSaving = true);
                    await settingsProv.updateSpecificSettings({
                      'enableLeaveReminders': val,
                    });
                    setState(() => _isSaving = false);
                  },
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required TextEditingController hourController,
    required TextEditingController minuteController,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTimeField(hourController, 'HH (00-23)')),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(child: _buildTimeField(minuteController, 'MM (00-59)')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 2,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_startHourController == null) return;

    final startH = _startHourController!.text.trim().padLeft(2, '0');
    final startM = _startMinuteController!.text.trim().padLeft(2, '0');
    final endH = _endHourController!.text.trim().padLeft(2, '0');
    final endM = _endMinuteController!.text.trim().padLeft(2, '0');

    // Validation (basic)
    if (int.tryParse(startH) == null ||
        int.parse(startH) > 23 ||
        int.tryParse(startM) == null ||
        int.parse(startM) > 59 ||
        int.tryParse(endH) == null ||
        int.parse(endH) > 23 ||
        int.tryParse(endM) == null ||
        int.parse(endM) > 59) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid time format. Use 00-23 for hours and 00-59 for minutes.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final settingsProv = context.read<SettingsProvider>();
    final success = await settingsProv.updateSpecificSettings({
      'workStartTime': '$startH:$startM',
      'workEndTime': '$endH:$endM',
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
