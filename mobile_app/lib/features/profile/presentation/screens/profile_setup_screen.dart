import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_service.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_primary_button.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../data/repository/profile_repository_impl.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;

  const ProfileSetupScreen({super.key, this.isEditMode = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final fullNameController = TextEditingController();

  final phoneNumberController = TextEditingController();

  final profileRepository = ProfileRepositoryImpl();

  final imagePicker = ImagePicker();

  static const int maxImageSizeInBytes = 5 * 1024 * 1024;

  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  XFile? selectedImage;

  String profileImagePath = "";

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthProvider>();

    if (auth.currentUser != null && auth.currentUser!.fullName.isNotEmpty) {
      fullNameController.text = auth.currentUser!.fullName;
    }

    if (auth.currentUser != null && auth.currentUser!.phoneNumber.isNotEmpty) {
      phoneNumberController.text = auth.currentUser!.phoneNumber;
    }

    if (auth.currentUser != null && auth.currentUser!.profileImage.isNotEmpty) {
      profileImagePath = auth.currentUser!.profileImage;
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();

    phoneNumberController.dispose();

    super.dispose();
  }

  String _resolveImageUrl(String imagePath) {
    if (imagePath.isEmpty) return "";

    if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
      return imagePath;
    }

    final baseUrl = DioClient.dio.options.baseUrl;

    final apiIndex = baseUrl.indexOf("/api");

    final host = apiIndex == -1 ? baseUrl : baseUrl.substring(0, apiIndex);

    if (imagePath.startsWith("/")) {
      return "$host$imagePath";
    }

    return "$host/$imagePath";
  }

  bool _isValidImageExtension(String filePath) {
    final segments = filePath.split('.');

    if (segments.length < 2) return false;

    final ext = segments.last.toLowerCase();

    return allowedExtensions.contains(ext);
  }

  Future<void> _setSelectedImage(XFile picked) async {
    if (!_isValidImageExtension(picked.path)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only JPG, PNG, and WEBP are allowed')),
      );

      return;
    }

    final bytes = await File(picked.path).length();

    if (bytes > maxImageSizeInBytes) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image size must be 5MB or less')),
      );

      return;
    }

    setState(() {
      selectedImage = picked;
    });
  }

  Future<void> _pickFromSource(ImageSource source) async {
    final picked = await imagePicker.pickImage(source: source);

    if (picked == null) return;

    await _setSelectedImage(picked);
  }

  Future<void> _pickProfileImage() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  await _pickFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  await _pickFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _continue() async {
    if (fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));

      return;
    }

    if (phoneNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your phone number")),
      );

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final auth = context.read<AuthProvider>();

    try {
      var latestProfileImagePath = profileImagePath;

      if (selectedImage != null) {
        latestProfileImagePath = await profileRepository.uploadProfileImage(
          filePath: selectedImage!.path,
        );
      }

      await profileRepository.updateProfile(
        fullName: fullNameController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        profileImage: latestProfileImagePath,
      );

      profileImagePath = latestProfileImagePath;

      await auth.updateProfileLocal(
        fullName: fullNameController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        profileImage: latestProfileImagePath,
      );

      await auth.markProfileCompleted();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to update profile right now")),
      );

      return;
    }

    if (!mounted) return;

    if (widget.isEditMode) {
      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));

      Navigator.pop(context);

      return;
    }

    final token = await StorageService.getToken();

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    await AppRouter.goToHome(context, token: token, user: auth.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final localImagePath = selectedImage?.path;

    final imageUrl = _resolveImageUrl(profileImagePath);

    return AuthScaffold(
      title: widget.isEditMode ? "Edit profile" : "Complete your profile",
      subtitle: widget.isEditMode
          ? "Update your details and profile photo."
          : "Add your details to personalize your CGM experience.",
      showBackButton: widget.isEditMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE6E8EC),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: localImagePath != null
                        ? Image.file(File(localImagePath), fit: BoxFit.cover)
                        : imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.grey,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: const Color(0xFF1E88E5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickProfileImage,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          AuthTextField(
            controller: fullNameController,
            label: "Full name",
            hint: "Jane Doe",
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller: phoneNumberController,
            label: "Phone number",
            hint: "+1 555 123 4567",
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _continue(),
          ),

          const SizedBox(height: 24),

          AuthPrimaryButton(
            label: widget.isEditMode ? "Save changes" : "Continue",
            isLoading: isSubmitting,
            onTap: _continue,
          ),
        ],
      ),
    );
  }
}
