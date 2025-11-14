import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/health_model.dart';
import '../models/mood_model.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  static ReportService get instance => _instance;

  /// Xuất dữ liệu sức khỏe ra CSV
  Future<File> exportHealthToCSV(
    List<HealthData> data,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Không có quyền truy cập lưu trữ');
    }

    final directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/health_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );

    final csvData = <List<dynamic>>[
      ['Ngày', 'Số bước', 'Cân nặng (kg)', 'Giờ ngủ', 'Chiều cao (cm)',
       'Huyết áp (SYS/DIA)', 'Nhịp tim (bpm)', 'Lượng nước (ml)',
       'Calo nạp', 'Calo tiêu'],
    ];

    for (var item in data) {
      if (item.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          item.date.isBefore(endDate.add(const Duration(days: 1)))) {
        csvData.add([
          DateFormat('dd/MM/yyyy').format(item.date),
          item.steps,
          item.weight,
          item.sleepHours,
          item.height ?? '',
          item.systolicBP != null && item.diastolicBP != null
              ? '${item.systolicBP}/${item.diastolicBP}'
              : '',
          item.heartRate ?? '',
          item.waterIntake ?? '',
          item.caloriesIn ?? '',
          item.caloriesOut ?? '',
        ]);
      }
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csvString);
    return file;
  }

  /// Xuất dữ liệu tâm trạng ra CSV
  Future<File> exportMoodToCSV(
    List<MoodData> data,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Không có quyền truy cập lưu trữ');
    }

    final directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/mood_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );

    final csvData = <List<dynamic>>[
      ['Ngày giờ', 'Tâm trạng', 'Mức stress', 'Ghi chú'],
    ];

    for (var item in data) {
      if (item.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          item.date.isBefore(endDate.add(const Duration(days: 1)))) {
        csvData.add([
          DateFormat('dd/MM/yyyy HH:mm').format(item.date),
          item.mood,
          item.stressLevel,
          item.note,
        ]);
      }
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csvString);
    return file;
  }

  /// Tạo báo cáo PDF tổng hợp
  Future<File> generatePDFReport({
    required List<HealthData> healthData,
    required List<MoodData> moodData,
    required DateTime startDate,
    required DateTime endDate,
    String? userName,
  }) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Không có quyền truy cập lưu trữ');
    }

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Tính toán thống kê
    final avgSteps = healthData.isNotEmpty
        ? healthData.map((e) => e.steps).reduce((a, b) => a + b) /
            healthData.length
        : 0.0;
    final avgWeight = healthData.isNotEmpty
        ? healthData.map((e) => e.weight).reduce((a, b) => a + b) /
            healthData.length
        : 0.0;
    final avgSleep = healthData.isNotEmpty
        ? healthData.map((e) => e.sleepHours).reduce((a, b) => a + b) /
            healthData.length
        : 0.0;

    final moodDistribution = <String, int>{};
    for (var mood in moodData) {
      moodDistribution[mood.mood] = (moodDistribution[mood.mood] ?? 0) + 1;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BÁO CÁO SỨC KHỎE TỔNG HỢP',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Người dùng: ${userName ?? "N/A"}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'Khoảng thời gian: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'Ngày tạo: ${dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Thống kê tổng quan
            pw.Text(
              'THỐNG KÊ TỔNG QUAN',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Chỉ số', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Giá trị trung bình', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Số bước chân'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(avgSteps.toStringAsFixed(0)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Cân nặng (kg)'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(avgWeight.toStringAsFixed(1)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Giờ ngủ (giờ)'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(avgSleep.toStringAsFixed(1)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Phân bố tâm trạng
            if (moodDistribution.isNotEmpty) ...[
              pw.Text(
                'PHÂN BỐ TÂM TRẠNG',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tâm trạng', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Số lần', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...moodDistribution.entries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(entry.value.toString()),
                          ),
                        ],
                      )),
                ],
              ),
            ],

            // Chi tiết dữ liệu
            pw.SizedBox(height: 20),
            pw.Text(
              'CHI TIẾT DỮ LIỆU SỨC KHỎE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Ngày', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Bước', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Cân nặng', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Giờ ngủ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...healthData.take(20).map((item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            dateFormat.format(item.date),
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.steps.toString(),
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.weight.toStringAsFixed(1),
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.sleepHours.toStringAsFixed(1),
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/health_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

