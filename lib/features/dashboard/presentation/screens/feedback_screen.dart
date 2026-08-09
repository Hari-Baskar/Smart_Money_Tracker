import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('FeedbackScreen');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      AnalyticsService.logEvent(
        'submit_feedback',
        parameters: {'type': _selectedType ?? 'Unknown'},
      );

      final type = _selectedType ?? 'Feedback';
      final description = _descriptionController.text;

      try {
        FocusScope.of(context).unfocus();
        final user = FirebaseAuth.instance.currentUser;

        await FirebaseFirestore.instance.collection('feedback').add({
          'type': type,
          'description': description,
          'userId': user?.uid ?? 'anonymous',
          'userEmail': user?.email ?? 'Unknown',
          'userName': user?.displayName ?? 'Unknown',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'new', // so you can track resolved/unresolved in console
        });

        if (mounted) {
          AppToast.show(context, 'Thank you for your feedback!');
          _descriptionController.clear();
          _typeController.clear();
          setState(() {
            _selectedType = null;
          });
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            'Failed to submit feedback. Please try again.',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Send Feedback', style: AppTextStyles.heading(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.w12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Feedback Type', style: AppTextStyles.subHeading(context)),
              SizedBox(height: AppSizes.h8),
              FormField<String>(
                initialValue: _selectedType,
                validator: (value) {
                  if (_selectedType == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
                builder: (FormFieldState<String> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownMenu<String>(
                        controller: _typeController,
                        width: AppSizes.screenWidth - (AppSizes.w16 * 2),
                        initialSelection: _selectedType,
                        hintText: 'Select Type',

                        textStyle: AppTextStyles.body(context),
                        menuStyle: MenuStyle(
                          backgroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.surface,
                          ),
                          surfaceTintColor: const MaterialStatePropertyAll(
                            Colors.transparent,
                          ),
                        ),
                        inputDecorationTheme: Theme.of(
                          context,
                        ).inputDecorationTheme,
                        dropdownMenuEntries: ['Bug', 'Improvement']
                            .map(
                              (type) => DropdownMenuEntry<String>(
                                value: type,
                                label: type,
                                style: MenuItemButton.styleFrom(
                                  textStyle: AppTextStyles.body(context),
                                ),
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                          state.didChange(value);
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: EdgeInsets.only(
                            top: AppSizes.h8,
                            left: AppSizes.w12,
                          ),
                          child: Text(
                            state.errorText ?? '',
                            style: AppTextStyles.small(
                              context,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: AppSizes.h24),
              Text('Description', style: AppTextStyles.subHeading(context)),
              SizedBox(height: AppSizes.h8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                style: AppTextStyles.body(context),
                decoration: InputDecoration(
                  hintText: 'Tell us more...',
                  hintStyle: AppTextStyles.body(context),
                  border: OutlineInputBorder(
                    borderRadius: AppSizes.boxBorderRadius,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.h32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.boxBorderRadius,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Feedback',
                    style: AppTextStyles.body(context, color: AppColors.white),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h24),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
