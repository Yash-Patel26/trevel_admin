import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../trips/presentation/pages/my_bookings_page.dart';
import 'saved_addresses_page.dart';
import '../../../../features/auth/data/auth_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;
    Color uploadColor = isDark ? Colors.amber.withOpacity(0.1) : const Color(0xFFFFF8E1);
    Color uploadIconColor = isDark ? Colors.white54 : Colors.black54;

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
                              "My Profile",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), 
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- Upload Image ---
                    Center(
                      child: Container(
                        width: 160,
                        height: 120,
                        decoration: BoxDecoration(
                          color: uploadColor, 
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_outlined, size: 32, color: uploadIconColor),
                            const SizedBox(height: 8),
                            Text("Upload image", style: TextStyle(color: uploadIconColor, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Form Fields ---
                    _buildLabel("Full Name", textColor),
                    _buildTextField(_nameController, "Enter Full Name", cardColor, textColor),
                    const SizedBox(height: 16),

                    _buildLabel("Phone Number", textColor),
                    _buildTextField(_phoneController, "Enter phone number", cardColor, textColor),
                    const SizedBox(height: 16),

                    _buildLabel("Email Address", textColor),
                    _buildTextField(_emailController, "Enter email address", cardColor, textColor),
                    const SizedBox(height: 16),

                    // --- Address Field (Clickable) ---
                    InkWell(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedAddressesPage()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            Text("Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.amber),
                          ],
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              // Basic Validation
              if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Email are required")));
                 return;
              }

              // Create update payload
              final data = {
                "name": _nameController.text,
                "email": _emailController.text,
                "mobile": _phoneController.text, // Optional if backend supports updating phone
              };

              // Import AuthRepository if not already
              // We'll trust imports are handled or add them
              // Calling AuthRepository().updateProfile(data)
              // Assuming AuthRepository is available. Importing it at top of file in next step if needed.
              
              showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));

              final success = await AuthRepository().updateProfile(data); // Needs import

              if (context.mounted) {
                Navigator.pop(context); // Close loader
                if (success) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
                   Navigator.pop(context); // Go back to ProfilePage
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
         color: cardColor,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey.withOpacity(0.2)),
         boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
         ]
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
