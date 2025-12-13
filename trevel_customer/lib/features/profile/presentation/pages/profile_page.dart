import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../trips/presentation/pages/my_bookings_page.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'settings_page.dart';
import '../../../../core/theme/theme_manager.dart';
import 'payments_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeManager.instance.themeMode == ThemeMode.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const CustomAppBar(showBackButton: false),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  children: [
                    // --- Header Title ---
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              "My Account",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Profile Info ---
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.person, size: 50, color: Colors.amber), 
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 4),
                              const Text("+91 9876543210", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()));
                          },
                          icon: Icon(Icons.edit_outlined, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Stats Card ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          _buildStatItem("0", "Total Trips", textColor),
                          Container(height: 30, width: 1, color: Colors.grey.shade300),
                          _buildStatItem("0g", "Co₂ Savings", textColor),
                          Container(height: 30, width: 1, color: Colors.grey.shade300),
                          _buildStatItem("0.00", "Trees Planted", textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Menu Items ---
                    _buildMenuItem(
                      Icons.account_balance_wallet_outlined, 
                      "Payment", 
                      "Add money, track expenses, and make quick payments", 
                      textColor,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsPage()));
                      }
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      Icons.headset_mic_outlined, 
                      "Help & Support", 
                      "Do you have questions or concerns? We got your back.",
                      textColor,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportPage()));
                      }
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(Icons.security_outlined, "Policy", "Read the documents to better understand travel.", textColor),
                    const Divider(height: 1),
                    _buildMenuItem(
                      Icons.settings_outlined, 
                      "Settings", 
                      "Your profile related settings and customization.",
                      textColor,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                      }
                    ),
                    const Divider(height: 1),
                    // Theme Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber),
                            ),
                            child: const Icon(Icons.brightness_6_outlined, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("App theme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                                const SizedBox(height: 4),
                                const Text("Customize your look: Dark mode and Light mode included.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: isDark, 
                            onChanged: (val) {
                              ThemeManager.instance.toggleTheme(val);
                            },
                            activeThumbColor: Colors.black,
                            activeTrackColor: Colors.amber, 
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // --- Action Buttons ---
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.delete_outline, color: textColor),
                            label: Text("Delete Account", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: textColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 2, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => const HomePage()), 
              (route) => false
            );
          } else if (index == 1) {
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => const MyBookingsPage()), 
              (route) => false
            );
          }
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color textColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber),
              ),
              child: Icon(icon, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}
