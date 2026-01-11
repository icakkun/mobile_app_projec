import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class PdfService {
  /// Generate Trip Summary PDF
  static Future<void> generateTripReport({
    required Trip trip,
    required List<Expense> expenses,
    required double totalSpent,
    required double remaining,
    required double percentage,
    required Map<String, double> categorySpent,
  }) async {
    final pdf = pw.Document();

    // Calculate stats
    final avgPerDay = _calculateAvgPerDay(trip, totalSpent);
    final expensesCount = expenses.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader('Trip Report'),
          pw.SizedBox(height: 20),

          // Trip Details Section
          _buildSectionTitle('Trip Details'),
          pw.SizedBox(height: 10),
          _buildTripDetailsCard(trip),
          pw.SizedBox(height: 20),

          // Budget Overview Section
          _buildSectionTitle('Budget Overview'),
          pw.SizedBox(height: 10),
          _buildBudgetOverview(
            trip: trip,
            totalSpent: totalSpent,
            remaining: remaining,
            percentage: percentage,
            expensesCount: expensesCount,
            avgPerDay: avgPerDay,
          ),
          pw.SizedBox(height: 20),

          // Category Breakdown Section
          if (trip.categoryBudgets.isNotEmpty) ...[
            _buildSectionTitle('Category Budgets'),
            pw.SizedBox(height: 10),
            ...trip.categoryBudgets.map((categoryBudget) {
              final spent = categorySpent[categoryBudget.categoryName] ?? 0;
              final catPercentage = categoryBudget.limitAmount == 0
                  ? 0.0
                  : (spent / categoryBudget.limitAmount * 100);
              return _buildCategoryBudgetItem(
                categoryName: categoryBudget.categoryName,
                spent: spent,
                limit: categoryBudget.limitAmount,
                percentage: catPercentage,
                currency: trip.homeCurrency,
              );
            }).toList(),
            pw.SizedBox(height: 20),
          ],

          // Expenses List Section
          _buildSectionTitle('Expense Details'),
          pw.SizedBox(height: 10),
          if (expenses.isEmpty)
            pw.Center(
              child: pw.Text(
                'No expenses recorded',
                style: pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: 14,
                ),
              ),
            )
          else
            _buildExpensesTable(expenses, trip.homeCurrency),

          // Footer
          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );

    await _showPdfPreviewAndShare(pdf, 'Trip_${trip.destination}_Report');
  }

  /// Generate Analytics Report PDF (All Trips)
  static Future<void> generateAnalyticsReport({
    required List<Trip> trips,
    required Map<String, double> tripSpent,
    required Map<String, int> tripExpenseCount,
    required Map<String, double> categoryTotals,
  }) async {
    final pdf = pw.Document();

    // Calculate overall stats
    final totalSpent = tripSpent.values.fold(0.0, (sum, val) => sum + val);
    final totalBudget = trips.fold(0.0, (sum, trip) => sum + trip.totalBudget);
    final totalExpenses =
        tripExpenseCount.values.fold(0, (sum, val) => sum + val);
    final avgPerTrip = trips.isEmpty ? 0.0 : totalSpent / trips.length;
    final budgetUsagePercentage =
        totalBudget == 0 ? 0.0 : (totalSpent / totalBudget) * 100;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader('Analytics Report'),
          pw.SizedBox(height: 20),

          // Overall Summary
          _buildSectionTitle('Overall Summary'),
          pw.SizedBox(height: 10),
          _buildOverallSummaryCard(
            totalSpent: totalSpent,
            totalBudget: totalBudget,
            totalExpenses: totalExpenses,
            avgPerTrip: avgPerTrip,
            budgetUsagePercentage: budgetUsagePercentage,
            tripCount: trips.length,
          ),
          pw.SizedBox(height: 20),

          // Trip Comparison
          _buildSectionTitle('Trip Comparison'),
          pw.SizedBox(height: 10),
          ...trips.map((trip) {
            final spent = tripSpent[trip.id] ?? 0;
            final expCount = tripExpenseCount[trip.id] ?? 0;
            final percentage =
                trip.totalBudget == 0 ? 0.0 : (spent / trip.totalBudget * 100);
            return _buildTripComparisonItem(
              trip: trip,
              spent: spent,
              expenseCount: expCount,
              percentage: percentage,
            );
          }).toList(),
          pw.SizedBox(height: 20),

          // Category Breakdown
          if (categoryTotals.isNotEmpty) ...[
            _buildSectionTitle('Top Categories'),
            pw.SizedBox(height: 10),
            _buildCategoryTotalsTable(categoryTotals, totalSpent),
          ],

          // Footer
          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );

    await _showPdfPreviewAndShare(pdf, 'Analytics_Report');
  }

  // ============================================
  // BUILDING BLOCKS
  // ============================================

  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#34D399'), // Trip Mint accent color
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TRIP MINT',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Text(
            DateFormat('MMM dd, yyyy').format(DateTime.now()),
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey400,
            width: 2,
          ),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#0B0F14'),
        ),
      ),
    );
  }

  static pw.Widget _buildTripDetailsCard(Trip trip) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                trip.destination,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                trip.homeCurrency,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#34D399'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${DateFormat('MMM dd, yyyy').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Duration: ${trip.endDate.difference(trip.startDate).inDays + 1} days',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBudgetOverview({
    required Trip trip,
    required double totalSpent,
    required double remaining,
    required double percentage,
    required int expensesCount,
    required double avgPerDay,
  }) {
    final color = percentage > 100
        ? PdfColors.red
        : percentage > 80
            ? PdfColors.orange
            : PdfColor.fromHex('#34D399');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Stats Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Budget',
                  'RM ${trip.totalBudget.toStringAsFixed(2)}', PdfColors.blue),
              _buildStatItem(
                  'Total Spent', 'RM ${totalSpent.toStringAsFixed(2)}', color),
              _buildStatItem('Remaining', 'RM ${remaining.toStringAsFixed(2)}',
                  PdfColors.green),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Expenses', expensesCount.toString(), PdfColors.purple),
              _buildStatItem('Avg/Day', 'RM ${avgPerDay.toStringAsFixed(2)}',
                  PdfColors.orange),
              _buildStatItem(
                  'Used', '${percentage.toStringAsFixed(1)}%', color),
            ],
          ),
          pw.SizedBox(height: 16),
          // Progress Bar
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Stack(
                  children: [
                    pw.Container(
                      width: (percentage / 100).clamp(0.0, 1.0) * 500,
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Budget Usage: ${percentage.toStringAsFixed(1)}%',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCategoryBudgetItem({
    required String categoryName,
    required double spent,
    required double limit,
    required double percentage,
    required String currency,
  }) {
    final color = percentage > 100
        ? PdfColors.red
        : percentage > 80
            ? PdfColors.orange
            : PdfColor.fromHex('#34D399');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                categoryName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'RM ${spent.toStringAsFixed(0)} / RM ${limit.toStringAsFixed(0)}',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            height: 8,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Stack(
              children: [
                pw.Container(
                  width: (percentage / 100).clamp(0.0, 1.0) * 500,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${percentage.toStringAsFixed(1)}% used',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExpensesTable(
      List<Expense> expenses, String currency) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
            _buildTableCell('Paid By', isHeader: true),
            _buildTableCell('Note', isHeader: true),
          ],
        ),
        // Rows
        ...expenses.map((expense) {
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('MMM dd').format(expense.expenseDate)),
              _buildTableCell(expense.categoryName),
              _buildTableCell('RM ${expense.amount.toStringAsFixed(2)}'),
              _buildTableCell(expense.paidBy),
              _buildTableCell(
                expense.note.isEmpty ? '-' : expense.note,
                maxLines: 2,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, int maxLines = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static pw.Widget _buildOverallSummaryCard({
    required double totalSpent,
    required double totalBudget,
    required int totalExpenses,
    required double avgPerTrip,
    required double budgetUsagePercentage,
    required int tripCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Total Spent',
                  'RM ${totalSpent.toStringAsFixed(2)}',
                  PdfColor.fromHex('#34D399')),
              _buildStatItem('Total Budget',
                  'RM ${totalBudget.toStringAsFixed(2)}', PdfColors.blue),
              _buildStatItem(
                  'Total Trips', tripCount.toString(), PdfColors.purple),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Total Expenses', totalExpenses.toString(), PdfColors.orange),
              _buildStatItem('Avg per Trip',
                  'RM ${avgPerTrip.toStringAsFixed(2)}', PdfColors.green),
              _buildStatItem(
                  'Budget Used',
                  '${budgetUsagePercentage.toStringAsFixed(1)}%',
                  PdfColors.red),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTripComparisonItem({
    required Trip trip,
    required double spent,
    required int expenseCount,
    required double percentage,
  }) {
    final color = percentage > 100
        ? PdfColors.red
        : percentage > 80
            ? PdfColors.orange
            : PdfColor.fromHex('#34D399');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                trip.destination,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'RM ${spent.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)} • $expenseCount expenses',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Stack(
                    children: [
                      pw.Container(
                        width: (percentage / 100).clamp(0.0, 1.0) * 450,
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryTotalsTable(
      Map<String, double> categoryTotals, double totalSpent) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
            _buildTableCell('Percentage', isHeader: true),
          ],
        ),
        // Rows
        ...sortedCategories.map((entry) {
          final percentage = (entry.value / totalSpent * 100);
          return pw.TableRow(
            children: [
              _buildTableCell(entry.key),
              _buildTableCell('RM ${entry.value.toStringAsFixed(2)}'),
              _buildTableCell('${percentage.toStringAsFixed(1)}%'),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Text(
          'Generated by Trip Mint - Travel Budget Planner',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(DateTime.now()),
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }

  // ============================================
  // HELPER FUNCTIONS
  // ============================================

  static double _calculateAvgPerDay(Trip trip, double totalSpent) {
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    return days > 0 ? totalSpent / days : totalSpent;
  }

  // ✅ WEB-COMPATIBLE: Different handling for web vs mobile
  static Future<void> _showPdfPreviewAndShare(
      pw.Document pdf, String fileName) async {
    if (kIsWeb) {
      // ✅ WEB: Just show preview with print/download options
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: fileName,
        format: PdfPageFormat.a4,
      );
    } else {
      // ✅ MOBILE: Preview + Share functionality
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: fileName,
        format: PdfPageFormat.a4,
      );

      // Also save to file and share on mobile
      try {
        final bytes = await pdf.save();
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName.pdf');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: fileName,
          text: 'Trip Mint Report - $fileName',
        );
      } catch (e) {
        print('Share error: $e');
        // Share failed, but preview already worked
      }
    }
  }
}
