import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../trips/presentation/pages/my_bookings_page.dart';
import 'profile_page.dart';
import '../../../../core/services/biometric_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Toggle States
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _locationServices = true;
  bool _shareLocation = true;
  bool _biometricAuth = false;
  bool _autoLock = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final enabled = await BiometricService().isBiometricEnabled();
    setState(() {
      _biometricAuth = enabled;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final service = BiometricService();
    if (value) {
      final supported = await service.isDeviceSupported();
      if (!supported) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Biometrics not supported on this device")));
        }
        return;
      }
      final authenticated = await service.authenticate();
      if (authenticated) {
        await service.setBiometricEnabled(true);
        setState(() => _biometricAuth = true);
      }
    } else {
      await service.setBiometricEnabled(false);
      setState(() => _biometricAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;

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
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header ---
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.amber,
                            child: const Icon(Icons.arrow_back, color: Colors.black),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Settings",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), 
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- Notifications Section ---
                    Text("Notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    _buildToggleCard(
                      icon: Icons.notifications_active,
                      title: "Push Notifications",
                      subtitle: "Receive notifications about your rides.",
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                      textColor: textColor,
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      icon: Icons.email,
                      title: "Email Notifications",
                      subtitle: "Receive ride confirmations via email.",
                      value: _emailNotifications,
                      onChanged: (val) => setState(() => _emailNotifications = val),
                      textColor: textColor,
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      icon: Icons.sms,
                      title: "SMS Notifications",
                      subtitle: "Receive ride updates via SMS.",
                      value: _smsNotifications,
                      onChanged: (val) => setState(() => _smsNotifications = val),
                      textColor: textColor,
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: 30),

                    // --- Privacy & Security Section ---
                    Text("Privacy & Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    _buildToggleCard(
                      icon: Icons.location_on,
                      title: "Location Services",
                      subtitle: "Allow the app to access your location.",
                      value: _locationServices,
                      onChanged: (val) => setState(() => _locationServices = val),
                      textColor: textColor,
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      icon: Icons.share_location,
                      title: "Share Location with Driver",
                      subtitle: "Let the driver see your real-time location.",
                      value: _shareLocation,
                      onChanged: (val) => setState(() => _shareLocation = val),
                      textColor: textColor,
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      icon: Icons.lock,
                      title: "Biometric Authentication",
                      subtitle: "Use Touch ID or Face ID to unlock.",
                      value: _biometricAuth,
                      onChanged: (val) => _toggleBiometrics(val),
                      textColor: textColor,
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      icon: Icons.timer,
                      title: "Auto Lock",
                      subtitle: "Lock the app when not in use.",
                      value: _autoLock,
                      onChanged: (val) => setState(() => _autoLock = val),
                      textColor: textColor,
                      cardColor: cardColor,
                      isDark: isDark,
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
          } else if (index == 2) {
             Navigator.pushAndRemoveUntil(
               context,
               MaterialPageRoute(builder: (context) => const ProfilePage()),
               (route) => false
             );
          }
        },
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color cardColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        children: [
          // Icon
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 16),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          
          // Switch
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDark ? Colors.white : Colors.black,
            activeTrackColor: Colors.amber,
            inactiveThumbColor: isDark ? Colors.white54 : Colors.black,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
