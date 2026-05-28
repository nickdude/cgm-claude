import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../welcome/presentation/screens/welcome_screen.dart';

import '../../../cgm/connect/presentation/providers/cgm_provider.dart';

import '../../../cgm/connect/presentation/screens/device_management_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  Future<void> _confirmDisconnectCgm(BuildContext context) async {
    final cgm = context.read<CGMProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Disconnect CGM"),
        content: const Text(
          "This will stop auto-reconnect and forget your paired sensor. "
          "You'll need to pair it again to resume readings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await cgm.disconnect();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("CGM disconnected")));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await authProvider.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final user = authProvider.currentUser;

    final fullName = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
        : "Welcome";

    final email = user?.email ?? "";

    final phoneNumber = user?.phoneNumber ?? "";

    final subtitle = phoneNumber.isEmpty ? email : "$email\n$phoneNumber";

    final profileImageUrl = _resolveImageUrl(user?.profileImage ?? "");

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x240F172A),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Text(
                                    _initialsFor(fullName),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Account',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Container(
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
                    buildTile(
                      icon: Icons.edit_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileSetupScreen(
                              isEditMode: true,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE9EEF5)),
                    buildTile(
                      icon: Icons.medical_services_rounded,
                      title: 'Connected Devices',
                      subtitle: 'Manage your sensor and pairing',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeviceManagementScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE9EEF5)),
                    buildTile(
                      icon: Icons.bluetooth_disabled_rounded,
                      title: 'Disconnect CGM',
                      subtitle: 'Safely unpair the current sensor',
                      onTap: () => _confirmDisconnectCgm(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFE9EEF5)),
                    buildTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Alerts and reminders',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE9EEF5)),
                    buildTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out from this device',
                      color: Colors.red,
                      onTap: () => _confirmLogout(context),
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

  static Widget buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.textPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: effectiveColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }

  static String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    String firstLetter(String value) => value.isNotEmpty ? value[0] : 'U';
    if (parts.length == 1) return firstLetter(parts.first).toUpperCase();
    return '${firstLetter(parts.first)}${firstLetter(parts.last)}'.toUpperCase();
  }
}
