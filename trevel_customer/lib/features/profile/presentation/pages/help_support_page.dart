import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../trips/presentation/pages/my_bookings_page.dart';
import 'profile_page.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int _selectedTabIndex = 0; // 0: FAQ, 1: Contact, 2: Support

  final List<String> _faqs = [
    "How do I book a ride?",
    "How do I cancel a ride?",
    "What payment methods are accepted?",
    "How is the fare calculated?",
    "What if I left something in the vehicle?",
    "How do I report a safety concern?",
    "Can I schedule a ride in advance?",
    "How do I update my profile information?",
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;
    Color itemColor = isDark ? Colors.grey[850]! : Colors.white;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black, // Keep outer black
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
                              "Help & Support",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), 
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Tabs ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabItem(0, "FAQ", textColor),
                        _buildTabItem(1, "Contact", textColor),
                        _buildTabItem(2, "Support", textColor),
                      ],
                    ),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 24),

                    // --- Content Switching ---
                    if (_selectedTabIndex == 0) 
                      _buildFaqTab(textColor, itemColor)
                    else if (_selectedTabIndex == 1)
                      _buildContactTab(textColor, itemColor)
                    else
                      _buildSupportTab(textColor, itemColor),

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

  Widget _buildTabItem(int index, String label, Color textColor) {
    bool isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.amber : textColor,
              ),
            ),
          ),
          if (isSelected)
            Container(
              height: 3,
              width: 40,
              color: Colors.amber,
            )
          else
             const SizedBox(height: 3),
        ],
      ),
    );
  }

  // --- FAQ Tab Content ---
  Widget _buildFaqTab(Color textColor, Color itemColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            "Frequently Asked Questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          ..._faqs.map((question) => _buildFaqItem(question, textColor, itemColor)),
      ],
    );
  }

  Widget _buildFaqItem(String question, Color textColor, Color itemColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              question,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  // --- Contact Tab Content ---
  Widget _buildContactTab(Color textColor, Color itemColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Send us a message",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 4),
        const Text(
          "Will get back to you within 24 hours.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        _buildTextField(Icons.person_outline, "Full Name", itemColor, textColor),
        const SizedBox(height: 12),
        _buildTextField(Icons.email_outlined, "Email", itemColor, textColor), 
        const SizedBox(height: 12),
         _buildTextField(Icons.subject, "Subject", itemColor, textColor),
        const SizedBox(height: 12),
        Container(
           height: 120,
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: itemColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                 BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Message",
                border: InputBorder.none,
                icon: Icon(Icons.message_outlined, color: Colors.amber),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: Colors.black), // TextField text should probably follow theme but let's see. If itemColor is dark, Text needs to be white.
              maxLines: 4,
            ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Send Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),

        const SizedBox(height: 30),
        Text(
          "Other ways to reach us",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
        ),
         const SizedBox(height: 16),
        _buildContactOption(Icons.email_outlined, "Email", "support@trevel.app", textColor),
        const SizedBox(height: 12),
        _buildContactOption(Icons.phone_outlined, "Phone", "+91 1800-TREVEL-1", textColor),
        const SizedBox(height: 12),
        _buildContactOption(Icons.chat_bubble_outline, "Live Chat", "Available 24/7", textColor),

      ],
    );
  }

  Widget _buildTextField(IconData icon, String hint, Color itemColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: TextField(
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          icon: Icon(icon, color: Colors.amber),
        ),
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
               const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ],
    );
  }


  // --- Support Tab Content ---
  Widget _buildSupportTab(Color textColor, Color itemColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Action",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 16),

        _buildQuickActionItem(
          icon: Icons.medical_services, // Replaced invalid icon
          iconColor: Colors.red,
          iconBgColor: Colors.red.shade50,
          title: "Emergency Support",
          subtitle: "Immediate assistance for urgent matters",
          onTap: () => _showEmergencyDialog(context),
          itemColor: itemColor,
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        _buildQuickActionItem(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          iconBgColor: Colors.orange.shade50,
          title: "Report an Issue",
          subtitle: "Report problems with your recent trip",
          onTap: () => _showReportIssueDialog(context),
          itemColor: itemColor,
          textColor: textColor,
        ),
         const SizedBox(height: 12),
        _buildQuickActionItem(
          icon: Icons.person_outline,
          iconColor: Colors.amber,
          iconBgColor: Colors.amber.shade50,
          title: "Account Help",
          subtitle: "Issues with login, profile, or payments",
          onTap: () => _showAccountHelpDialog(context),
          itemColor: itemColor,
          textColor: textColor,
        ),
         const SizedBox(height: 12),
        _buildQuickActionItem(
          icon: Icons.chat_bubble_outline,
          iconColor: Colors.green,
          iconBgColor: Colors.green.shade50,
          title: "Send Feedback",
          subtitle: "Share your thoughts, suggestions, or compliments",
          onTap: () => _showSendFeedbackDialog(context),
          itemColor: itemColor,
          textColor: textColor,
        ),

        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: itemColor,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: const [
                   Icon(Icons.access_time, color: Colors.amber, size: 20),
                   SizedBox(width: 8),
                   Text("Support Hours", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), // Title color
                 ],
               ),
               const SizedBox(height: 12),
               _buildSupportHourRow("Phone Support", "Mon-Sun: 6:00 AM - 12:00 AM", textColor),
               _buildSupportHourRow("Live Chat", "Available 24/7", textColor),
               _buildSupportHourRow("Email Support", "Mon-Sun: 24/7 (48h response)", textColor),
               _buildSupportHourRow("Emergency Line", "Available 24/7", textColor),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color itemColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
             BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHourRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
          Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- Dialogs ---
  
  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medical_services, color: Colors.red, size: 40),
                const SizedBox(height: 16),
                const Text(
                  "Emergency Support",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "If this is a medical or safety emergency, please call emergency services immediately.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  "For urgent app-related issues:",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                 const Text(
                  "Emergency Hotline: +91 1800-911-911\nAvailable 24/7",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.red,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Call Now"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                   child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30)
                ),
                const SizedBox(height: 16),
                const Text(
                  "Report an Issue",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "What type of issue would you like to report?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                 Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.amber,
                           foregroundColor: Colors.black,
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Continue"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                   child: const Icon(Icons.account_circle, color: Colors.amber, size: 30)
                ),
                const SizedBox(height: 16),
                const Text(
                  "Account Help",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Common account issues:\n\u2022 Login problems\n\u2022 Profile update issues\n\u2022 Payment method troubles\n\u2022 Account verification",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                 Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.amber,
                           foregroundColor: Colors.black,
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Get Help"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSendFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                   child: const Icon(Icons.chat_bubble_outline, color: Colors.green, size: 30)
                ),
                const SizedBox(height: 16),
                const Text(
                  "Send Feedback",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "We value your feedback!\nShare your thoughts, suggestions, or compliments to help us improve.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                 Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.amber,
                           foregroundColor: Colors.black,
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Send Feedback"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
