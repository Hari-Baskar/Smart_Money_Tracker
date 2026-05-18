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
            style: AppTextStyles.body(context, color: Colors.white),
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
        title: Text('Send Feedback', style: AppTextStyles.headline(context)),
        centerTitle: true,
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
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: Text('Select Type', style: AppTextStyles.small(context)),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w16,
                    vertical: AppSizes.h12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                ),
                items: ['Bug', 'Improvement']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: AppTextStyles.body(context)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
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
                      color: Colors.white,
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
