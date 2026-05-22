import 'dart:io';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';

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
        AppToast.show(context, 'Please enter your name', isError: true);
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
          AppToast.show(context, 'Profile updated successfully');
          Navigator.pop(context);
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(context, 'Failed to update profile: $e', isError: true);
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
            size: AppSizes.r20,
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
              padding: EdgeInsets.only(right: AppSizes.w16),
              child: Center(
                child: SizedBox(
                  width: AppSizes.r20,
                  height: AppSizes.r20,
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
          padding: EdgeInsets.all(AppSizes.r24),
          child: Column(
            children: [
              SizedBox(height: AppSizes.h20),
              // Profile Image with Edit Overlay
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSizes.r(4)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: AppSizes.r(60),
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
                                size: AppSizes.r(60),
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
                          padding: EdgeInsets.all(AppSizes.r8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: AppSizes.r20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.h40),

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
                  SizedBox(height: AppSizes.h12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSizes.r16),
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
                          size: AppSizes.r20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(AppSizes.r16),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSizes.h32),
              
              // Tips/Note
              Container(
                padding: EdgeInsets.all(AppSizes.r16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSizes.r16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: AppSizes.r20,
                    ),
                    SizedBox(width: AppSizes.w12),
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
