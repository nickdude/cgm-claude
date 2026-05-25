import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';

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

    final profileImageUrl = _resolveImageUrl(user?.profileImage ?? "");

    final subtitle = phoneNumber.isEmpty ? email : "$email\n$phoneNumber";

    return AuthScaffold(
      title: fullName,
      subtitle: subtitle,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6E8EC)),
            ),
            child: Column(
              children: [
                buildTile(
                  icon: Icons.edit,
                  title: "Edit Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfileSetupScreen(isEditMode: true),
                      ),
                    );
                  },
                ),
                const Divider(),
                buildTile(
                  icon: Icons.medical_services,
                  title: "Connected Devices",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeviceManagementScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                buildTile(
                  icon: Icons.bluetooth_disabled,
                  title: "Disconnect CGM",
                  onTap: () => _confirmDisconnectCgm(context),
                ),
                const Divider(),
                buildTile(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notification settings coming soon"),
                      ),
                    );
                  },
                ),
                const Divider(),
                buildTile(
                  icon: Icons.logout,
                  title: "Logout",
                  color: Colors.red,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
