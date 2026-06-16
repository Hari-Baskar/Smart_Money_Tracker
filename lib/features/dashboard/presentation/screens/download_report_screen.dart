import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';

class DownloadReportScreenArgs {
  final List<TransactionModel> transactions;
  final String filterString;

  const DownloadReportScreenArgs({
    required this.transactions,
    required this.filterString,
  });
}

class DownloadReportScreen extends HookConsumerWidget {
  final DownloadReportScreenArgs args;

  const DownloadReportScreen({super.key, required this.args});

  String generateCsvContent(List<TransactionModel> txns) {
    final buffer = StringBuffer();
    buffer.writeln(
      "Date,Merchant,Category,Subcategory,Amount,Type,Payment Method,Bank",
    );

    String _csvVal(String? val) {
      if (val == null || val.trim().isEmpty) return 'NULL';
      return val.replaceAll('"', '""');
    }

    for (var t in txns) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
      buffer.writeln(
        '"$dateStr",'
        '"${_csvVal(t.merchant)}",'
        '"${_csvVal(t.category)}",'
        '"${_csvVal(t.subcategory)}",'
        '${t.amount},'
        '"${t.type.name}",'
        '"${_csvVal(t.paymentMethodId)}",'
        '"${_csvVal(t.bankId)}"',
      );
    }
    return buffer.toString();
  }

  Future<Uint8List> generateExcelBytes(List<TransactionModel> txns) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Merchant'),
      TextCellValue('Category'),
      TextCellValue('Subcategory'),
      TextCellValue('Amount'),
      TextCellValue('Type'),
      TextCellValue('Payment Method'),
      TextCellValue('Bank'),
    ]);

    String _excelVal(String? val) {
      if (val == null || val.trim().isEmpty) return 'NULL';
      return val;
    }

    for (var t in txns) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
      sheet.appendRow([
        TextCellValue(dateStr),
        TextCellValue(_excelVal(t.merchant)),
        TextCellValue(_excelVal(t.category)),
        TextCellValue(_excelVal(t.subcategory)),
        DoubleCellValue(t.amount),
        TextCellValue(t.type.name),
        TextCellValue(_excelVal(t.paymentMethodId)),
        TextCellValue(_excelVal(t.bankId)),
      ]);
    }

    final centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (int r = 0; r < sheet.maxRows; r++) {
      for (int c = 0; c < sheet.maxColumns; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle = centerStyle;
      }
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  Future<Uint8List> generatePdfBytes(List<TransactionModel> txns) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load(AppStrings.appIconPath);
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Failed to load PDF logo: $e');
    }

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in txns) {
      if (t.type == TransactionType.credit) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    final headers = ['Date', 'Merchant', 'Category', 'Amount', 'Type'];

    String _pdfVal(String? val) {
      if (val == null || val.trim().isEmpty) return '-';
      return val;
    }

    final data = txns.map((t) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
      final amtStr = t.amount.toStringAsFixed(2);
      final typeStr = t.type.name.toUpperCase();
      return [
        dateStr,
        _pdfVal(t.merchant),
        _pdfVal(t.category),
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
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Filter: ${args.filterString}   |   Records: ${txns.length}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.teal700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.Divider(color: PdfColors.grey300, thickness: 1),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      border: pw.Border.all(color: PdfColors.green100),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Income',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.green700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          totalIncome.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
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
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      border: pw.Border.all(color: PdfColors.red100),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Expenses',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.red700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          totalExpense.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColors.grey200,
                  width: 0.5,
                ),
                verticalInside: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
              cellHeight: 25,
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 9),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = useMemoized(
      () => DateFormat('dd MMM yyyy (h.mm a)').format(DateTime.now()),
      [],
    );

    // Suggest download loadable file name
    final defaultFileName = useMemoized(
      () => '${args.filterString} Transactions - $dateStr',
      [args.filterString, dateStr],
    );
    final fileNameController = useTextEditingController(text: defaultFileName);

    final selectedFormat = useState<String>('PDF');
    final isExporting = useState(false);
    final exportedFile = useState<File?>(null);

    useEffect(() {
      AnalyticsService.logScreenView('DownloadReportScreen');
      exportedFile.value = null;
      return null;
    }, [selectedFormat.value]);

    final updateStateAsync = ref.watch(updateProvider);
    final updateState = updateStateAsync.value;
    final showAds = updateState?.config?.showAds ?? false;
    final testAds = updateState?.config?.testAds ?? false;

    final rewardedAd = useState<RewardedAd?>(null);
    final isAdLoaded = useState(false);

    void loadRewardedAd() {
      final adUnitId = testAds
          ? 'ca-app-pub-3940256099942544/5224354917'
          : AppStrings.androidRewardedAdUnitId;

      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAd.value = ad;
            isAdLoaded.value = true;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                isAdLoaded.value = false;
                rewardedAd.value = null;
                loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                isAdLoaded.value = false;
                rewardedAd.value = null;
                loadRewardedAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Failed to load rewarded ad: $error');
            isAdLoaded.value = false;
            rewardedAd.value = null;
          },
        ),
      );
    }

    useEffect(() {
      if (showAds) {
        loadRewardedAd();
      }
      return () {
        rewardedAd.value?.dispose();
      };
    }, [showAds, testAds]);

    Future<void> handleExport() async {
      final baseName = fileNameController.text.trim();
      if (baseName.isEmpty) {
        AppToast.show(context, 'Please enter a file name', isError: true);
        return;
      }

      isExporting.value = true;
      final trace = await AnalyticsService.startTrace('generate_report_trace');
      try {
        final directory = await getApplicationDocumentsDirectory();
        String extension = '';
        if (selectedFormat.value == 'PDF') {
          extension = '.pdf';
        } else if (selectedFormat.value == 'Excel') {
          extension = '.xlsx';
        } else {
          extension = '.csv';
        }

        final fullFileName = '$baseName$extension';
        final file = File('${directory.path}/$fullFileName');

        if (selectedFormat.value == 'PDF') {
          final pdfBytes = await generatePdfBytes(args.transactions);
          await file.writeAsBytes(pdfBytes);
        } else if (selectedFormat.value == 'Excel') {
          final excelBytes = await generateExcelBytes(args.transactions);
          await file.writeAsBytes(excelBytes);
        } else {
          final csvContent = generateCsvContent(args.transactions);
          await file.writeAsString(csvContent);
        }

        exportedFile.value = file;
        AnalyticsService.logEvent(
          'download_report',
          parameters: {'format': selectedFormat.value},
        );
      } catch (e, stack) {
        AppToast.show(context, 'Export failed: $e', isError: true);
        AnalyticsService.logError(e, stack, reason: 'Failed to export report');
      } finally {
        await AnalyticsService.stopTrace(trace);
        isExporting.value = false;
      }
    }

    Future<void> showAdAndExport() async {
      if (showAds && isAdLoaded.value && rewardedAd.value != null) {
        AnalyticsService.logEvent('watch_ad_to_export');
        await rewardedAd.value!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            handleExport();
          },
        );
      } else {
        handleExport();
      }
    }

    Future<void> downloadToDevice() async {
      if (exportedFile.value == null) return;
      try {
        final file = exportedFile.value!;

        await MediaStore.ensureInitialized();
        MediaStore.appFolder = 'Finzo- (Smart Money Tracker)';

        // media_store_plus automatically deletes the temp file passed to it,
        // so we must create a copy so our app can keep using the original file.
        final tempDir = await getTemporaryDirectory();
        final tempFileForMediaStore = await file.copy('${tempDir.path}/${file.uri.pathSegments.last}');

        final savedInfo = await MediaStore().saveFile(
          tempFilePath: tempFileForMediaStore.path,
          dirType: DirType.download,
          dirName: DirName.download,
        );

        if (savedInfo != null) {
          debugPrint('File saved to: ${savedInfo.uri}');
          AppToast.show(context, 'Downloaded successfully');
        } else {
          AppToast.show(context, 'Download failed.');
        }
      } catch (e) {
        AppToast.show(context, 'Failed to save: $e', isError: true);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.getText(context),
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Download Report', style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.w16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Name',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.getTextMuted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSizes.h8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: AppSizes.boxBorderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: fileNameController,
                      style: AppTextStyles.body(context),
                      decoration: InputDecoration(
                        hintText: 'Enter file name',
                        border: OutlineInputBorder(
                          borderRadius: AppSizes.boxBorderRadius,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(AppSizes.r16),
                        suffixText: selectedFormat.value == 'PDF'
                            ? '.pdf'
                            : selectedFormat.value == 'Excel'
                            ? '.xlsx'
                            : '.csv',
                        suffixStyle: AppTextStyles.body(
                          context,
                          color: AppColors.getTextMuted(
                            context,
                          ).withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizes.h24),

                  Text(
                    'Select Format',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSizes.h12),

                  // Format options
                  _buildFormatOption(
                    context: context,
                    title: 'PDF Document (.pdf)',
                    description: 'Best for viewing, sharing, and printing.',
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: AppColors.red,
                    value: 'PDF',
                    selectedValue: selectedFormat.value,
                    onChanged: (val) => selectedFormat.value = val,
                  ),
                  SizedBox(height: AppSizes.h12),
                  _buildFormatOption(
                    context: context,
                    title: 'Excel Spreadsheet (.xlsx)',
                    description:
                        'Compatible with Microsoft Excel for advanced calculations.',
                    icon: Icons.table_view_rounded,
                    iconColor: AppColors.green,
                    value: 'Excel',
                    selectedValue: selectedFormat.value,
                    onChanged: (val) => selectedFormat.value = val,
                  ),
                  SizedBox(height: AppSizes.h12),
                  _buildFormatOption(
                    context: context,
                    title: 'Google Sheets / CSV (.csv)',
                    description:
                        'Universal table format, easy to import to Google Sheets.',
                    icon: Icons.insert_chart_rounded,
                    iconColor: AppColors.blue,
                    value: 'Sheets',
                    selectedValue: selectedFormat.value,
                    onChanged: (val) => selectedFormat.value = val,
                  ),
                  SizedBox(height: AppSizes.h32),

                  // Banner Ad above the button
                  const BannerAdWidget(forceBanner: true),
                  SizedBox(height: AppSizes.h16),

                  if (exportedFile.value == null)
                    ElevatedButton.icon(
                      onPressed: isExporting.value ? null : showAdAndExport,
                      icon: isExporting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : null,
                      label: Text(
                        isExporting.value
                            ? 'Generating...'
                            : showAds
                            ? 'Watch Ad to Export'
                            : 'Export & Download',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: Size(double.infinity, AppSizes.h(48)),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSizes.cardBorderRadius,
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      padding: EdgeInsets.all(AppSizes.r16),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.08),
                        borderRadius: AppSizes.cardBorderRadius,
                        border: Border.all(
                          color: AppColors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.green,
                              ),
                              SizedBox(width: AppSizes.w12),
                              Expanded(
                                child: Text(
                                  'Ready to Share',
                                  style: AppTextStyles.body(
                                    context,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.h8),
                          Text(
                            exportedFile.value!.path.split('/').last,
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                          SizedBox(height: AppSizes.h16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: AppSizes.h(48),
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Share.shareXFiles([
                                        XFile(exportedFile.value!.path),
                                      ], text: 'My Transactions Export');
                                    },
                                    icon: const Icon(Icons.share_rounded),
                                    label: Text(
                                      'Share',
                                      style: AppTextStyles.body(
                                        context,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppSizes.cardBorderRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSizes.w12),
                              Expanded(
                                child: SizedBox(
                                  height: AppSizes.h(48),
                                  child: ElevatedButton.icon(
                                    onPressed: downloadToDevice,
                                    label: Text(
                                      'Download',
                                      style: AppTextStyles.body(
                                        context,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppSizes.cardBorderRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppSizes.h48),
                  ],
                ],
              ),
            ),
          ),

          // Ad banner at bottom
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: AppSizes.cardBorderRadius,
      child: Container(
        padding: EdgeInsets.all(AppSizes.r16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: AppSizes.cardBorderRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.getTextMuted(context).withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.r8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.r24),
            ),
            SizedBox(width: AppSizes.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(
                      context,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    description,
                    style: AppTextStyles.small(
                      context,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: selectedValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
