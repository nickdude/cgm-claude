import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../auth/presentation/screens/login_screen.dart';

class ProfileScreen
    extends StatelessWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    final user =
        authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Profile"),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                4,
              ),

              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      AppColors.primary,
                  width: 2,
                ),

                shape: BoxShape.circle,
              ),

              child: const CircleAvatar(
                radius: 50,

                backgroundColor:
                    Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              user?.fullName ??
                  "Puja Sharma",

              style: const TextStyle(
                fontSize: 24,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              user?.email ??
                  "puja@gmail.com",
            ),

            const SizedBox(height: 40),

            Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),

              child: Column(
                children: [
                  buildTile(
                    icon: Icons.edit,

                    title: "Edit Profile",

                    onTap: () {},
                  ),

                  const Divider(),

                  buildTile(
                    icon: Icons
                        .medical_services,

                    title:
                        "Connected Devices",

                    onTap: () {},
                  ),

                  const Divider(),

                  buildTile(
                    icon:
                        Icons.logout,

                    title: "Logout",

                    onTap: () async {
                      await authProvider
                          .logout();

                      Navigator
                          .pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(),
                        ),
                        (route) =>
                            false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),

      title: Text(title),

      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),

      onTap: onTap,
    );
  }
}