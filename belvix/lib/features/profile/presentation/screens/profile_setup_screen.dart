import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_service.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_primary_button.dart';
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

  String _extensionOf(String value) {
    // Strip any query/fragment (content URIs) before reading the extension.
    final cleaned = value.split('?').first.split('#').first;

    final dot = cleaned.lastIndexOf('.');

    if (dot == -1 || dot == cleaned.length - 1) return '';

    return cleaned.substring(dot + 1).toLowerCase();
  }

  bool _isValidImage(XFile picked) {
    // Prefer the file name (most reliable), then the path.
    final ext = _extensionOf(picked.name).isNotEmpty
        ? _extensionOf(picked.name)
        : _extensionOf(picked.path);

    if (ext.isNotEmpty) return allowedExtensions.contains(ext);

    // Some gallery/content URIs expose no extension — fall back to the
    // mime type, and if that's missing too, allow it (image_picker only
    // ever returns images).
    final mime = picked.mimeType?.toLowerCase() ?? '';

    if (mime.isEmpty) return true;

    return mime.contains('jpeg') ||
        mime.contains('jpg') ||
        mime.contains('png') ||
        mime.contains('webp');
  }

  Future<void> _setSelectedImage(XFile picked) async {
    if (!_isValidImage(picked)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only JPG, JPEG, PNG, and WEBP are allowed'),
        ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.isEditMode)
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.maybePop(context),
                        child: const SizedBox(
                          height: 42,
                          width: 42,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                  if (widget.isEditMode) const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Update your details and profile photo.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE8EDF4),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEDEEF1),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
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
                                        size: 44,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 44,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              color: const Color(0xFF64748B),
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
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile setup',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Keep your profile photo and details up to date.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8EDF4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0B0F172A),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AuthTextField(
                      controller: fullNameController,
                      label: 'Full name',
                      hint: 'Jane Doe',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: phoneNumberController,
                      label: 'Phone number',
                      hint: '+1 555 123 4567',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _continue(),
                    ),
                    const SizedBox(height: 24),
                    AuthPrimaryButton(
                      label: widget.isEditMode ? 'Save changes' : 'Continue',
                      isLoading: isSubmitting,
                      onTap: _continue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
