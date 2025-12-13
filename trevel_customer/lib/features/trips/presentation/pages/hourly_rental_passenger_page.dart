import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import 'ride_preview_page.dart'; // Will likely link to Preview or similar later. For now just placeholder or Preview.

class HourlyRentalPassengerPage extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const HourlyRentalPassengerPage({super.key, required this.bookingDetails});

  @override
  State<HourlyRentalPassengerPage> createState() => _HourlyRentalPassengerPageState();
}

class _HourlyRentalPassengerPageState extends State<HourlyRentalPassengerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fill if "Myself" was selected in previous step (optional feature, but good UX)
    if (widget.bookingDetails['travelerType'] == 0) {
      _nameController.text = "Yash Patel";
      _phoneController.text = "9876543210";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for top area
      body: Stack(
        children: [
          Column(
            children: [
               const CustomAppBar(showBackButton: false),
               Expanded(
                 child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Header ---
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.amber,
                                  radius: 20,
                                  child: Icon(Icons.arrow_back, color: Colors.black),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "Hourly Rentals",
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40), 
                            ],
                          ),
                          const SizedBox(height: 20),

                          // --- Stepper (Step 2 Active) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepCircle("1", false, isDark),
                              _buildStepLine(),
                              _buildStepCircle("2", true, isDark),
                              _buildStepLine(),
                              _buildStepCircle("3", false, isDark),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // --- Form Fields ---
                          _buildLabel("Full Name", Icons.person_outline, textColor),
                          const SizedBox(height: 8),
                          _buildInputBox(hint: "Enter Full Name", controller: _nameController, isDark: isDark, textColor: textColor),
                          
                          const SizedBox(height: 20),
                          _buildLabel("Phone Number", Icons.phone_outlined, textColor),
                          const SizedBox(height: 8),
                          _buildInputBox(hint: "Enter phone number", controller: _phoneController, isDark: isDark, textColor: textColor),

                          const SizedBox(height: 40),
                          
                          // --- Buttons: Back & Proceed ---
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.amber),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text("Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      // Navigate to Next Step or Completion
                                      // Merging details
                                      final updatedDetails = Map<String, dynamic>.from(widget.bookingDetails);
                                      updatedDetails['passengerName'] = _nameController.text;
                                      updatedDetails['passengerPhone'] = _phoneController.text;

                                      // For now, let's assume it goes to a Preview page similar to others, 
                                      // or if the user wants a Step 3 (Payment), we can stub it. 
                                      // Using RidePreviewPage as generic end-point for now or just print.
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => RidePreviewPage(bookingDetails: updatedDetails)));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text("Proceed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                  ),
                                ),
                              ),
                            ],
                          )

                        ],
                      ),
                    ),
                 ),
               ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 0, 
        onTap: (index) {
           if (index == 0) Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildStepCircle(String text, bool isActive, bool isDark) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? Colors.amber : (isDark ? Colors.transparent : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: isActive ? Colors.white : Colors.amber, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.amber,
    );
  }

  Widget _buildLabel(String text, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildInputBox({String? hint, TextEditingController? controller, required bool isDark, required Color textColor}) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: innerCardColor,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        style: TextStyle(color: textColor),
      ),
    );
  }
}
