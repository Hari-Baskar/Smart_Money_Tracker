import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_filter_screen.dart';
import '../widgets/expandable_transaction_card.dart';
import '../widgets/history_summary_card.dart';
import '../widgets/history_analysis_view.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = useState(
      HistoryFilterState(
        dateRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
        category: 'All',
        subcategory: 'All',
      ),
    );

    final showAnalysis = useState(false);
    final analysisType = useState('Expenses');

    final downloadedFileName = useState<String?>(null);
    final downloadedFilePath = useState<String?>(null);

    String generateCsvContent(List<TransactionModel> txns) {
      final buffer = StringBuffer();
      buffer.writeln("ID,Date,Merchant,Category,Subcategory,Amount,Type,Reference,Payment Method,Bank");
      for (var t in txns) {
        final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(t.date);
        buffer.writeln(
          '"${t.id}",'
          '"$dateStr",'
          '"${t.merchant.replaceAll('"', '""')}",'
          '"${t.category.replaceAll('"', '""')}",'
          '"${t.subcategory.replaceAll('"', '""')}",'
          '${t.amount},'
          '"${t.type.name}",'
          '"${(t.reference ?? '').replaceAll('"', '""')}",'
          '"${(t.paymentMethodId ?? '').replaceAll('"', '""')}",'
          '"${(t.bankId ?? '').replaceAll('"', '""')}"'
        );
      }
      return buffer.toString();
    }

    Future<Uint8List> generatePdfBytes(List<TransactionModel> txns) async {
      final pdf = pw.Document();

      // Load app logo dynamically from the single source of truth
      pw.MemoryImage? logoImage;
      try {
        final ByteData bytes = await rootBundle.load(AppStrings.appIconPath);
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        debugPrint('Failed to load PDF logo: $e');
      }

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      for (var t in txns) {
        if (t.type == TransactionType.credit) {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }
      final netBalance = totalIncome - totalExpense;

      final headers = ['Date', 'Merchant', 'Category', 'Amount', 'Type'];
      
      final data = txns.map((t) {
        final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
        final amtStr = t.amount.toStringAsFixed(2);
        final typeStr = t.type.name.toUpperCase();
        return [
          dateStr,
          t.merchant,
          t.category,
          amtStr,
          typeStr,
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null) ...[
                      pw.Container(
                        width: 40,
                        height: 40,
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Image(logoImage),
                      ),
                    ],
                    pw.Text(
                      '${AppStrings.baseAppName.replaceAll('₹ ', '').toUpperCase()} REPORT',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Transaction History Export',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}   |   Records: ${txns.length}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 15),

              // Summary Cards
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.green100),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Income', style: pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
                          pw.SizedBox(height: 4),
                          pw.Text(totalIncome.toStringAsFixed(2), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.red100),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Expenses', style: pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                          pw.SizedBox(height: 4),
                          pw.Text(totalExpense.toStringAsFixed(2), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Table
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                cellHeight: 25,
                cellAlignment: pw.Alignment.center,
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal700,
                ),
              ),
            ];
          },
        ),
      );

      return pdf.save();
    }

    Future<void> exportData(String format, List<TransactionModel> filteredTransactions) async {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final dateStr = DateFormat('dd-MM-yyyy_HHmmss').format(DateTime.now());
        
        final activeFilters = <String>[];
        if (filterState.value.transactionType != null) {
          activeFilters.add(filterState.value.transactionType == TransactionType.credit ? 'Income' : 'Expense');
        }
        if (filterState.value.category != 'All') {
          activeFilters.add(filterState.value.category);
        }
        if (filterState.value.subcategory != 'All') {
          activeFilters.add(filterState.value.subcategory);
        }
        if (filterState.value.bankId != null) {
          activeFilters.add('Bank');
        }
        if (filterState.value.paymentMethodId != null) {
          activeFilters.add('Payment');
        }
        final filterStr = activeFilters.isEmpty ? 'All' : activeFilters.join('-');

        String fileName = '';
        if (format == 'Excel') {
          fileName = 'transactions_${dateStr}_($filterStr).xlsx';
          final fileContent = generateCsvContent(filteredTransactions);
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(fileContent);
        } else if (format == 'PDF') {
          fileName = 'transactions_${dateStr}_($filterStr).pdf';
          final pdfBytes = await generatePdfBytes(filteredTransactions);
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pdfBytes);
        } else { // Sheets
          fileName = 'transactions_${dateStr}_($filterStr).csv';
          final fileContent = generateCsvContent(filteredTransactions);
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(fileContent);
        }
        
        downloadedFileName.value = fileName;
        downloadedFilePath.value = '${directory.path}/$fileName';
        AppToast.show(context, 'Exported as $format successfully');
      } catch (e) {
        AppToast.show(context, 'Export failed: $e');
      }
    }


    Future<void> openFilterScreen() async {
      final result = await context.push<HistoryFilterState>(
        '/history-filter',
        extra: filterState.value,
      );
      if (result != null) {
        filterState.value = result;
      }
    }

    // Shortcuts
    final selectedCategory = filterState.value.category;
    final selectedSubcategory = filterState.value.subcategory;
    final dateRange = filterState.value.dateRange;
    final selectedBankId = filterState.value.bankId;
    final selectedPaymentMethodId = filterState.value.paymentMethodId;
    final activeFilterCount = [
      selectedCategory != 'All',
      selectedSubcategory != 'All',
      selectedBankId != null,
      selectedPaymentMethodId != null,
      filterState.value.transactionType != null,
    ].where((v) => v).length;

    final startOfRange = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    );
    final endOfRange = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      23,
      59,
      59,
      999,
    );
    final adjustedRange = DateTimeRange(start: startOfRange, end: endOfRange);

    final transactionsAsync = ref.watch(
      transactionsInDateRangeProvider(adjustedRange),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: showAnalysis.value
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => showAnalysis.value = false,
              )
            : IconButton(
                icon: Icon(Icons.menu_rounded, size: AppSizes.r(28)),
                onPressed: () => ref
                    .read(mainScaffoldKeyProvider)
                    .currentState
                    ?.openDrawer(),
              ),
        title: Text(
          showAnalysis.value ? 'Analysis' : 'History',
          style: AppTextStyles.heading(context),
        ),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  size: AppSizes.r(24),
                  color: filterState.value.hasActiveFilters
                      ? AppColors.primary
                      : null,
                ),
                tooltip: 'Filters',
                onPressed: openFilterScreen,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: AppSizes.r(16),
                    height: AppSizes.r(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.w12),
        child: Column(
          children: [

            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // 1. Filter by Date Range (already handled by provider range)
                  final dateFiltered = transactions.where((t) {
                    return t.date.isAfter(
                          dateRange.start.subtract(
                            const Duration(seconds: 1),
                          ),
                        ) &&
                        t.date.isBefore(
                          dateRange.end.add(const Duration(days: 1)),
                        );
                  }).toList();

                  // 2. Filter by Category, Subcategory, Bank, PaymentMethod & Calculate Totals
                  double totalSpent = 0;
                  double totalIncome = 0;
                  final List<TransactionModel> finalFiltered = [];

                  for (var t in dateFiltered) {
                    // Transaction Type filter
                    if (filterState.value.transactionType != null &&
                        t.type != filterState.value.transactionType) {
                      continue;
                    }
                    // Bank filter
                    if (selectedBankId != null && t.bankId != selectedBankId) {
                      continue;
                    }
                    // Payment method filter
                    if (selectedPaymentMethodId != null &&
                        t.paymentMethodId != selectedPaymentMethodId) {
                      continue;
                    }

                    if (selectedCategory == 'All') {
                      final subcategoryMatch = selectedSubcategory == 'All' ||
                          t.subcategory == selectedSubcategory;
                      if (subcategoryMatch) {
                        finalFiltered.add(t);
                        if (t.type == TransactionType.credit) {
                          totalIncome += t.amount;
                        } else {
                          totalSpent += t.amount;
                        }
                      }
                    } else {
                      if (t.splits.isEmpty) {
                        final categoryMatch = t.category == selectedCategory;
                        final subcategoryMatch = selectedSubcategory == 'All' ||
                            t.subcategory == selectedSubcategory;
                        if (categoryMatch && subcategoryMatch) {
                          finalFiltered.add(t);
                          if (t.type == TransactionType.credit) {
                            totalIncome += t.amount;
                          } else {
                            totalSpent += t.amount;
                          }
                        }
                      } else {
                        // Transaction has splits, and category filter is NOT 'All'.
                        double splitTotal = 0;
                        int splitIndex = 0;
                        for (var split in t.splits) {
                          splitTotal += split.amount;
                          final categoryMatch =
                              split.category == selectedCategory;
                          final subcategoryMatch =
                              selectedSubcategory == 'All' ||
                              split.subcategory == selectedSubcategory;

                          if (categoryMatch && subcategoryMatch) {
                            final virtualTxn = TransactionModel(
                              id: '${t.id}_split_$splitIndex',
                              amount: split.amount,
                              merchant: t.merchant,
                              date: split.date ?? t.date,
                              type: t.type,
                              category: split.category,
                              subcategory: split.subcategory,
                              rawSms: t.rawSms,
                              splits: const [],
                              isEdited: t.isEdited,
                              reference: t.reference,
                              bankId: t.bankId,
                              paymentMethodId: t.paymentMethodId,
                            );
                            finalFiltered.add(virtualTxn);
                            if (t.type == TransactionType.credit) {
                              totalIncome += split.amount;
                            } else {
                              totalSpent += split.amount;
                            }
                          }
                          splitIndex++;
                        }

                        final remainder = t.amount - splitTotal;
                        if (remainder > 0.01) {
                          final categoryMatch = t.category == selectedCategory;
                          final subcategoryMatch =
                              selectedSubcategory == 'All' ||
                              t.subcategory == selectedSubcategory;
                          if (categoryMatch && subcategoryMatch) {
                            final virtualRemainder = TransactionModel(
                              id: '${t.id}_remainder',
                              amount: remainder,
                              merchant: t.merchant,
                              date: t.date,
                              type: t.type,
                              category: t.category,
                              subcategory: t.subcategory,
                              rawSms: t.rawSms,
                              splits: const [],
                              isEdited: t.isEdited,
                              reference: t.reference,
                              bankId: t.bankId,
                              paymentMethodId: t.paymentMethodId,
                            );
                            finalFiltered.add(virtualRemainder);
                            if (t.type == TransactionType.credit) {
                              totalIncome += remainder;
                            } else {
                              totalSpent += remainder;
                            }
                          }
                        }
                      }
                    }
                  }

                  if (finalFiltered.isEmpty) {
                    return _buildEmptyState(
                      context,
                      filterState.value.hasActiveFilters
                          ? 'No transactions match your filters'
                          : 'No transactions found for this selection',
                      filterState.value.hasActiveFilters
                          ? openFilterScreen
                          : null,
                    );
                  }

                  return ListView(
                    children: [
                      // Dynamic Summary Card
                      HistorySummaryCard(
                        selectedCategory: selectedCategory,
                        selectedSubcategory: selectedSubcategory,
                        totalSpent: totalSpent,
                        totalIncome: totalIncome,
                        incomeCount: finalFiltered
                            .where((t) => t.type == TransactionType.credit)
                            .length,
                        expenseCount: finalFiltered
                            .where((t) => t.type != TransactionType.credit)
                            .length,
                      ),
                      SizedBox(height: AppSizes.h12),

                      // Banner Ad
                      const BannerAdWidget(),
                      SizedBox(height: AppSizes.h12),

                      // Downloaded File Name Banner
                      if (downloadedFileName.value != null) ...[
                        Container(
                          padding: EdgeInsets.all(AppSizes.r12),
                          margin: EdgeInsets.only(bottom: AppSizes.h12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: AppSizes.cardBorderRadius,
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green),
                              SizedBox(width: AppSizes.w12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'File Downloaded Successfully',
                                      style: AppTextStyles.body(context, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      downloadedFileName.value!,
                                      style: AppTextStyles.small(context, color: AppColors.getTextMuted(context)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_rounded, color: Colors.green),
                                onPressed: () {
                                  if (downloadedFilePath.value != null) {
                                    Share.shareXFiles([XFile(downloadedFilePath.value!)], text: 'Exported Transactions');
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  downloadedFileName.value = null;
                                  downloadedFilePath.value = null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Header with Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  showAnalysis.value
                                      ? 'Analysis'
                                      : selectedCategory == 'All'
                                      ? 'All Transactions'
                                      : selectedSubcategory == 'All'
                                      ? '$selectedCategory Transactions'
                                      : '$selectedCategory > $selectedSubcategory',
                                  style: AppTextStyles.body(
                                    context,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (selectedBankId != null || selectedPaymentMethodId != null)
                                  Text(
                                    [
                                      if (selectedBankId != null)
                                        PaymentConstants.getBankName(selectedBankId),
                                      if (selectedPaymentMethodId != null)
                                        PaymentConstants.getPaymentMethodName(selectedPaymentMethodId),
                                    ].join(' · '),
                                    style: AppTextStyles.small(
                                      context,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    builder: (context) {
                                      return SafeArea(
                                        child: Padding(
                                          padding: EdgeInsets.all(AppSizes.r16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Export Transactions',
                                                style: AppTextStyles.heading(context),
                                              ),
                                              SizedBox(height: AppSizes.h12),
                                              Text(
                                                'Choose your preferred format to export the filtered transactions.',
                                                style: AppTextStyles.body(context, color: AppColors.getTextMuted(context)),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: AppSizes.h20),
                                              ListTile(
                                                leading: const Icon(Icons.table_view_rounded, color: Colors.green),
                                                title: Text('Export as Excel (.xlsx)', style: AppTextStyles.body(context)),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  exportData('Excel', finalFiltered);
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                                                title: Text('Export as PDF (.pdf)', style: AppTextStyles.body(context)),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  exportData('PDF', finalFiltered);
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.insert_chart_rounded, color: Colors.blue),
                                                title: Text('Export as Sheets (.csv)', style: AppTextStyles.body(context)),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  exportData('Sheets', finalFiltered);
                                                },
                                              ),
                                              const Divider(),
                                              SizedBox(height: AppSizes.h8),
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  try {
                                                    final directory = await getApplicationDocumentsDirectory();
                                                    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                                                    final fileName = 'transactions_export_$timestamp.csv';
                                                    final file = File('${directory.path}/$fileName');
                                                    await file.writeAsString(generateCsvContent(finalFiltered));
                                                    
                                                    await Share.shareXFiles([XFile(file.path)], text: 'My Transactions Export');
                                                  } catch (e) {
                                                    AppToast.show(context, 'Share failed: $e');
                                                  }
                                                },
                                                icon: const Icon(Icons.share_rounded),
                                                label: const Text('Share Transactions'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: AppColors.white,
                                                  minimumSize: Size(double.infinity, AppSizes.h(48)),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: AppSizes.cardBorderRadius,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: Icon(
                                  Icons.download_rounded,
                                  size: AppSizes.r(18),
                                  color: AppColors.primary,
                                ),
                                label: Text(
                                  'Download',
                                  style: AppTextStyles.body(
                                    context,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSizes.w4),
                              TextButton.icon(
                                onPressed: () =>
                                    showAnalysis.value = !showAnalysis.value,
                                icon: Icon(
                                  showAnalysis.value
                                      ? Icons.history_rounded
                                      : Icons.analytics_rounded,
                                  size: AppSizes.r(18),
                                  color: AppColors.primary,
                                ),
                                label: Text(
                                  showAnalysis.value
                                      ? 'History'
                                      : 'Analysis',
                                  style: AppTextStyles.body(
                                    context,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (showAnalysis.value)
                        HistoryAnalysisView(
                          transactions: finalFiltered,
                          analysisType: analysisType,
                        )
                      else
                        ..._groupAndBuildTransactions(context, finalFiltered),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _groupAndBuildTransactions(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final sortedTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in sortedTransactions) {
      final dateKey = DateFormat('MMMM dd, yyyy').format(t.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(t);
    }

    List<Widget> widgets = [];
    for (var dateKey in grouped.keys) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
          child: Text(
            dateKey,
            style: AppTextStyles.body(context, color: AppColors.primary),
          ),
        ),
      );
      widgets.addAll(
        grouped[dateKey]!.map((t) => _buildTransactionCard(context, t)),
      );
    }
    return widgets;
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message, [
    VoidCallback? onAdjustFilters,
  ]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: AppSizes.r(64),
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: AppSizes.h16),
          Text(
            message,
            style: AppTextStyles.body(
              context,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAdjustFilters != null) ...[  
            SizedBox(height: AppSizes.h12),
            TextButton.icon(
              onPressed: onAdjustFilters,
              icon: Icon(Icons.tune_rounded, size: AppSizes.r16),
              label: const Text('Adjust Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return ExpandableTransactionCard(
      transaction: t,
      margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
      onTap: () {
        context.push('/transaction-detail', extra: t);
      },
    );
  }
}
