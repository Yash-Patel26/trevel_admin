import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../trips/presentation/pages/my_bookings_page.dart';
import 'profile_page.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  String _selectedType = 'Home'; // Default selection

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    Color lightGrey = isDark ? Colors.grey[800]! : const Color(0xFFF9FAFB);

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
                              "Select location",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), 
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Search Bar ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: innerCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        boxShadow: [
                           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset:const Offset(0, 2))
                        ]
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search area",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Map Placeholder ---
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/map_placeholder.png'), // Using placeholder
                          fit: BoxFit.cover,
                        )
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: const [
                           Icon(Icons.location_on, size: 40, color: Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Address Details Section ---
                    Text("Address details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: innerCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        boxShadow: [
                           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Enter your  location",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          icon: Icon(Icons.location_on, color: textColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: innerCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        boxShadow: [
                           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          hintText: "Address details E.g. Floor, flat no, Town",
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // --- Save address as ---
                    Text("Save address as", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTypeChip("Home", Icons.home_outlined, isDark, lightGrey),
                        const SizedBox(width: 12),
                        _buildTypeChip("Work", Icons.work_outline, isDark, lightGrey),
                        const SizedBox(width: 12),
                        _buildTypeChip("Other", Icons.location_on_outlined, isDark, lightGrey),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Add Image Button ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: lightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 30, color: textColor),
                          const SizedBox(height: 8),
                          Text("Add an image", style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Save Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.pop(context); // Go back after save
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Save address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
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

  Widget _buildTypeChip(String label, IconData icon, bool isDark, Color unselectedColor) {
    bool isSelected = _selectedType == label;
    Color selectedBgColor = isDark ? Colors.teal.withOpacity(0.3) : const Color(0xFFE0F2F1);
    Color iconColor = isSelected ? Colors.teal : Colors.grey[700]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : unselectedColor,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: Colors.teal.shade200) : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
