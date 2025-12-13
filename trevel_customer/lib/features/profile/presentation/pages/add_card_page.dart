import 'package:flutter/material.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  String _selectedCurrency = "India"; // Default mock value

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
     // Light background for this specific page based on design, or stick to app theme
    Color backgroundColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Custom Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
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
                         "Add card",
                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                       ),
                     ),
                   ),
                   const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    // --- Card Number ---
                    Text("Card Number", style: TextStyle(fontSize: 16, color: textColor)),
                    const SizedBox(height: 8),
                    _buildInputBox(
                      controller: _cardNumberController,
                      icon: Icons.credit_card,
                      suffixIcon: Icons.camera_alt_outlined,
                      isDark: isDark,
                      textColor: textColor
                    ),
                    const SizedBox(height: 20),

                    // --- Expiry & CVV Row ---
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Expiration Date", style: TextStyle(fontSize: 16, color: textColor)),
                              const SizedBox(height: 8),
                              _buildInputBox(
                                controller: _expiryDateController,
                                suffixIcon: Icons.help_outline,
                                isDark: isDark,
                                textColor: textColor
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text("CVV", style: TextStyle(fontSize: 16, color: textColor)),
                               const SizedBox(height: 8),
                               _buildInputBox(
                                 controller: _cvvController,
                                 suffixIcon: Icons.help_outline,
                                 isDark: isDark,
                                 textColor: textColor
                               ),
                             ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Card Currency ---
                    Text("Card Currency", style: TextStyle(fontSize: 16, color: textColor)),
                    const SizedBox(height: 8),
                    _buildCurrencyDropdown(isDark, textColor),

                    const SizedBox(height: 40),

                    // --- Next Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                           // TODO: Implement add card logic
                           Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Next", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller, 
    IconData? icon, 
    IconData? suffixIcon, 
    required bool isDark, 
    required Color textColor
  }) {
    Color fillColor = isDark ? Colors.grey[850]! : Colors.grey[100]!; 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: icon != null ? Icon(icon, color: Colors.grey) : null,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: isDark ? Colors.white60 : Colors.black54) : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: TextStyle(color: textColor, fontSize: 16),
      ),
    );
  }

  Widget _buildCurrencyDropdown(bool isDark, Color textColor) {
    Color fillColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white60 : Colors.black54),
          dropdownColor: fillColor,
          style: TextStyle(color: textColor, fontSize: 16),
          items: [
            DropdownMenuItem(
              value: "India",
              child: Row(
                children: [
                  // Flag placeholder (using generic icon or container if image not available, 
                  // but ideally should be an asset. For now, using a colored box or text)
                  Container(width: 24, height: 16, color: Colors.orange), 
                  const SizedBox(width: 12),
                  const Text("India"),
                ],
              ),
            ),
             DropdownMenuItem(
              value: "USA",
              child: Row(
                children: [
                  Container(width: 24, height: 16, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Text("USA"),
                ],
              ),
            ),
          ], 
          onChanged: (val) {
            setState(() {
              _selectedCurrency = val!;
            });
          },
        ),
      ),
    );
  }
}
