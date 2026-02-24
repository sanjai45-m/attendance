import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:attendance/models/attendance_model.dart';
import 'package:attendance/core/utils/date_utils.dart';

class ExcelService {
  /// Generate and save attendance report as Excel file
  Future<String> generateReport(List<AttendanceModel> records) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Attendance Report';

    // ─── Header styling ─────────────────────────────
    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.fontSize = 12;
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.backColor = '#6C63FF';
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    // ─── Headers ────────────────────────────────────
    final headers = [
      'Employee ID',
      'Name',
      'Date',
      'Punch In',
      'Punch Out',
      'Total Hours',
      'Status'
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = headerStyle;
      cell.columnWidth = i == 1 ? 25 : 18; // wider for Name column
    }

    // ─── Data rows ──────────────────────────────────
    final Style dataStyle = workbook.styles.add('dataStyle');
    dataStyle.fontSize = 11;
    dataStyle.hAlign = HAlignType.center;
    dataStyle.vAlign = VAlignType.center;

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final row = i + 2;

      sheet.getRangeByIndex(row, 1)
        ..setText(record.employeeId)
        ..cellStyle = dataStyle;
      sheet.getRangeByIndex(row, 2)
        ..setText(record.employeeName)
        ..cellStyle = dataStyle;
      sheet.getRangeByIndex(row, 3)
        ..setText(record.date)
        ..cellStyle = dataStyle;
      sheet.getRangeByIndex(row, 4)
        ..setText(record.punchIn != null
            ? AppDateUtils.toTimeString(record.punchIn!)
            : '--')
        ..cellStyle = dataStyle;
      sheet.getRangeByIndex(row, 5)
        ..setText(record.punchOut != null
            ? AppDateUtils.toTimeString(record.punchOut!)
            : '--')
        ..cellStyle = dataStyle;
      sheet.getRangeByIndex(row, 6)
        ..setText(record.totalHoursFormatted)
        ..cellStyle = dataStyle;
      sheet.getRangeByIndex(row, 7)
        ..setText(record.status.displayName)
        ..cellStyle = dataStyle;

      // Color-code status
      final statusCell = sheet.getRangeByIndex(row, 7);
      final Style statusStyle = workbook.styles.add('status_$i');
      statusStyle.fontSize = 11;
      statusStyle.hAlign = HAlignType.center;
      statusStyle.bold = true;
      switch (record.status.toJson()) {
        case 'present':
          statusStyle.fontColor = '#00E676';
          break;
        case 'late':
          statusStyle.fontColor = '#FFAB40';
          break;
        case 'absent':
          statusStyle.fontColor = '#FF5252';
          break;
      }
      statusCell.cellStyle = statusStyle;
    }

    // ─── Save file ──────────────────────────────────
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/attendance_report_$timestamp.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  /// Open the generated Excel file
  Future<void> openFile(String filePath) async {
    await OpenFilex.open(filePath);
  }

  /// Share the generated Excel file
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Attendance Report');
  }
}
