import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      // Handle submission logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thank you for your feedback!',
            style: AppTextStyles.body(context, color: AppColors.white),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Send Feedback', style: AppTextStyles.headline(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.w16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feedback Type',
                style: AppTextStyles.headline(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
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
                        width: AppSizes.screenWidth - (AppSizes.w16 * 2),
                        initialSelection: _selectedType,
                        hintText: 'Select Type',
                        textStyle: AppTextStyles.body(context),
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w16,
                            vertical: AppSizes.h12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.r12),
                            borderSide: BorderSide.none,
                          ),
                        ),
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
              Text(
                'Description',
                style: AppTextStyles.headline(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: AppSizes.h8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                style: AppTextStyles.body(context),
                decoration: InputDecoration(
                  hintText: 'Tell us more...',
                  hintStyle: AppTextStyles.small(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r12),
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
                      borderRadius: BorderRadius.circular(AppSizes.r12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit Feedback',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
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
}
