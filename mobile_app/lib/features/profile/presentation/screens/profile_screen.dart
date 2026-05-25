import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../welcome/presentation/screens/welcome_screen.dart';

import '../../../cgm/connect/presentation/providers/cgm_provider.dart';

import '../../../cgm/connect/presentation/screens/device_management_screen.dart';

class ProfileScreen
    extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void>
      _confirmDisconnectCgm(
    BuildContext context,
  ) async {
    final cgm = context
        .read<CGMProvider>();

    final confirm = await showDialog<
        bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
        title: const Text(
          "Disconnect CGM",
        ),
        content: const Text(
          "This will stop auto-reconnect and forget your paired sensor. "
          "You'll need to pair it again to resume readings.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text(
              "Cancel",
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text(
              "Disconnect",
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await cgm.disconnect();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "CGM disconnected",
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
  ) async {
    final authProvider = context
        .read<AuthProvider>();

    final confirm = await showDialog<
        bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
        title: const Text("Logout"),
        content: const Text(
          "Are you sure you want to logout?",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text(
              "Cancel",
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text(
              "Logout",
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await authProvider.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    final user =
        authProvider.currentUser;

    final fullName = (user?.fullName
                .isNotEmpty ??
            false)
        ? user!.fullName
        : "Welcome";

    final email = user?.email ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                4,
              ),
              decoration:
                  BoxDecoration(
                border: Border.all(
                  color:
                      AppColors.primary,
                  width: 2,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const CircleAvatar(
                radius: 50,
                backgroundColor:
                    Colors.white,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors
                      .primary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              email,
              style: const TextStyle(
                color: AppColors
                    .textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(24),
              ),
              child: Column(
                children: [
                  buildTile(
                    icon:
                        Icons.edit,
                    title:
                        "Edit Profile",
                    onTap: () {
                      ScaffoldMessenger
                              .of(
                                context,
                              )
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Edit Profile coming soon",
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  buildTile(
                    icon: Icons
                        .medical_services,
                    title:
                        "Connected Devices",
                    onTap: () {
                      Navigator
                          .push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  const DeviceManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  buildTile(
                    icon: Icons
                        .bluetooth_disabled,
                    title:
                        "Disconnect CGM",
                    onTap: () =>
                        _confirmDisconnectCgm(
                      context,
                    ),
                  ),
                  const Divider(),
                  buildTile(
                    icon: Icons
                        .notifications_none,
                    title:
                        "Notifications",
                    onTap: () {
                      ScaffoldMessenger
                              .of(
                                context,
                              )
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Notification settings coming soon",
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  buildTile(
                    icon:
                        Icons.logout,
                    title: "Logout",
                    color:
                        Colors.red,
                    onTap: () =>
                        _confirmLogout(
                      context,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
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
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
