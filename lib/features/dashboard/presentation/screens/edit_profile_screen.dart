import 'dart:io';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final nameController = useTextEditingController();
    final selectedImagePath = useState<String?>(null);
    final isSaving = useState(false);
    final isMounted = useIsMounted();

    // Initialize controller when data is available
    useEffect(() {
      userProfileAsync.whenData((profile) {
        if (nameController.text.isEmpty) {
          nameController.text = profile['name'] ?? '';
        }
      });
      return null;
    }, [userProfileAsync]);

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        selectedImagePath.value = pickedFile.path;
      }
    }

    Future<void> saveProfile() async {
      if (nameController.text.trim().isEmpty) {
        Fluttertoast.showToast(msg: 'Please enter your name');
        return;
      }

      isSaving.value = true;
      try {
        String? photoUrl;
        if (selectedImagePath.value != null) {
          photoUrl = await ref
              .read(authNotifierProvider.notifier)
              .uploadProfileImage(selectedImagePath.value!);
        }

        await ref.read(authNotifierProvider.notifier).updateProfile(
              name: nameController.text.trim(),
              photoUrl: photoUrl,
            );

        if (isMounted()) {
          Fluttertoast.showToast(msg: 'Profile updated successfully');
          Navigator.pop(context);
        }
      } catch (e) {
        if (isMounted()) {
          Fluttertoast.showToast(msg: 'Failed to update profile');
        }
      } finally {
        if (isMounted()) isSaving.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: 20.r,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.headline(context),
        ),
        actions: [
          if (isSaving.value)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: saveProfile,
              child: Text(
                'Save',
                style: AppTextStyles.body(
                  context,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              // Profile Image with Edit Overlay
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.primary.withOpacity(0.05),
                        backgroundImage: selectedImagePath.value != null
                            ? FileImage(File(selectedImagePath.value!))
                            : (profile['photoUrl'] != null
                                ? NetworkImage(profile['photoUrl']!)
                                : null) as ImageProvider?,
                        child: selectedImagePath.value == null &&
                                profile['photoUrl'] == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 60.r,
                                color: AppColors.primary.withOpacity(0.3),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 20.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),

              // Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Full Name',
                    style: AppTextStyles.small(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: nameController,
                      style: AppTextStyles.body(context),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: AppTextStyles.small(
                          context,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                          size: 20.r,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(16.r),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),
              
              // Tips/Note
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Your name and profile picture will be visible across the app and on your shared expense reports.',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
