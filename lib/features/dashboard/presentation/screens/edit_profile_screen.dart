import 'dart:io';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:smart_money_tracker/core/common/widgets/app_text_field.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/constants/app_toast_messages.dart';
import 'package:smart_money_tracker/core/common/widgets/modal_action_sheet.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final nameController = useTextEditingController();
    final selectedImagePath = useState<String?>(null);
    final isSaving = useState(false);
    final isMounted = useIsMounted();

    useEffect(() {
      AnalyticsService.logScreenView('EditProfileScreen');
      return null;
    }, const []);

    // Initialize controller when data is available
    useEffect(() {
      userProfileAsync.whenData((profile) {
        if (nameController.text.isEmpty) {
          nameController.text = profile['name'] ?? '';
        }
      });
      return null;
    }, [userProfileAsync]);

    Future<void> pickImageSource(ImageSource source) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressQuality: 70,
          maxWidth: 512,
          maxHeight: 512,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              cropStyle: CropStyle.circle,
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              cropStyle: CropStyle.circle,
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
        );

        if (croppedFile != null) {
          selectedImagePath.value = croppedFile.path;
        }
      }
    }

    Future<void> showImageSourceBottomSheet() async {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.transparent,
        builder: (bottomSheetContext) => ModalActionSheet(
          children: [
            ModalActionItem(
              icon: Icons.camera_alt_outlined,
              title: 'Take photo',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                pickImageSource(ImageSource.camera);
              },
            ),
            ModalActionItem(
              icon: Icons.photo_library_outlined,
              title: 'Choose from gallery',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                pickImageSource(ImageSource.gallery);
              },
            ),
            if (selectedImagePath.value != null ||
                (userProfileAsync.value?['photoUrl'] != null))
              ModalActionItem(
                icon: Icons.delete_outline_rounded,
                title: 'Remove current photo',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  if (selectedImagePath.value != null) {
                    selectedImagePath.value = null;
                  } else {
                    isSaving.value = true;
                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .removeProfileImage();
                      if (context.mounted) {
                        AppToast.show(
                          context,
                          AppToastMessages.profilePhotoRemoved,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppToast.show(
                          context,
                          AppToastMessages.profilePhotoRemoveFailed,
                          isError: true,
                        );
                      }
                    } finally {
                      if (isMounted()) isSaving.value = false;
                    }
                  }
                },
              ),
          ],
        ),
      );
    }

    Future<void> saveProfile() async {
      FocusScope.of(context).unfocus();

      if (nameController.text.trim().isEmpty) {
        AppToast.show(context, AppToastMessages.nameRequired, isError: true);
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

        await ref
            .read(authNotifierProvider.notifier)
            .updateProfile(
              name: nameController.text.trim(),
              photoUrl: photoUrl,
            );

        if (isMounted()) {
          AppToast.show(context, AppToastMessages.profileUpdated);
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(
            context,
            AppToastMessages.profileUpdateFailed,
            isError: true,
          );
        }
      } finally {
        if (isMounted()) isSaving.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: AppTextStyles.subHeading(context)),
      ),
      body: userProfileAsync.hasValue && userProfileAsync.value != null
          ? Builder(
              builder: (context) {
                final profile = userProfileAsync.value!;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(AppSizes.w12),
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
                                  color: AppColors.isDark(context)
                                      ? AppColors.white.withOpacity(0.1)
                                      : AppColors.black.withOpacity(0.05),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: AppSizes.r(60),
                                backgroundColor: AppColors.isDark(context)
                                    ? AppColors.white.withOpacity(0.05)
                                    : AppColors.black.withOpacity(0.02),
                                backgroundImage: selectedImagePath.value != null
                                    ? FileImage(File(selectedImagePath.value!))
                                    : (profile['photoUrl'] != null
                                              ? NetworkImage(
                                                  profile['photoUrl']!,
                                                )
                                              : null)
                                          as ImageProvider?,
                                child:
                                    selectedImagePath.value == null &&
                                        profile['photoUrl'] == null
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: AppSizes.r(60),
                                        color: AppColors.primary.withOpacity(
                                          0.3,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: showImageSourceBottomSheet,
                                child: Container(
                                  padding: EdgeInsets.all(AppSizes.r8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: AppSizes.r20,
                                    color: AppColors.white,
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
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: AppSizes.h12),
                          AppTextField(
                            controller: nameController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                            ],
                            hintText: 'Enter your name',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: AppSizes.r20,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSizes.h32),

                      // Tips/Note
                      Container(
                        padding: EdgeInsets.all(AppSizes.r16),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceContainerLowest(context),
                          borderRadius: AppSizes.boxBorderRadius,
                          border: Border.all(
                            color: AppColors.isDark(context)
                                ? AppColors.white.withOpacity(0.05)
                                : AppColors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: AppSizes.r20,
                            ),
                            SizedBox(width: AppSizes.w12),
                            Expanded(
                              child: Text(
                                'Your name and profile picture will be visible across the app and on your shared expense reports.',
                                style: AppTextStyles.small(
                                  context,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : userProfileAsync.hasError
          ? Center(
              child: Text(
                'Something went wrong',
                style: AppTextStyles.body(context),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: userProfileAsync.hasValue && userProfileAsync.value != null
          ? SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.w12,
                      AppSizes.h12,
                      AppSizes.w12,
                      AppSizes.h12,
                    ),
                    child: PrimaryButton(
                      text: 'Save Profile',
                      onPressed: saveProfile,
                      isLoading: isSaving.value,
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              ),
            )
          : null,
    );
  }
}
