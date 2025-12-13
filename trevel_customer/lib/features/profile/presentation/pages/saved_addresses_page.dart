import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../trips/presentation/pages/my_bookings_page.dart';
import 'add_address_page.dart';
import 'profile_page.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;

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
                              "Select an address",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), 
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- Add Address Button ---
                    InkWell(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAddressPage()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: innerCardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          boxShadow: [
                             BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ]
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 20, color: textColor),
                            const SizedBox(width: 12),
                            Text("Add Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.amber, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Saved Addresses Title ---
                    Text("Saved addresses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),

                    // --- Address Cards ---
                    _buildAddressCard(
                      icon: Icons.home_outlined,
                      label: "Home",
                      distance: "5.3 kms",
                      address: "address of home",
                      phone: "Phone number:",
                      bgColor: innerCardColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    _buildAddressCard(
                      icon: Icons.work_outline,
                      label: "Work",
                      distance: "9.3 kms",
                      address: "address of work",
                      phone: "Phone number:",
                      bgColor: innerCardColor,
                      textColor: textColor,
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

  Widget _buildAddressCard({
    required IconData icon,
    required String label,
    required String distance,
    required String address,
    required String phone,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, size: 28, color: textColor),
              const SizedBox(height: 4),
              Text(distance, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text(address, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 12),
                Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.amber.shade100,
            child: const Icon(Icons.arrow_forward, size: 16, color: Colors.black), 
          ),
        ],
      ),
    );
  }
}
