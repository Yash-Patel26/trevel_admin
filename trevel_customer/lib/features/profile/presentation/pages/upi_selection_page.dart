import 'package:flutter/material.dart';

class UpiSelectionPage extends StatelessWidget {
  const UpiSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
     // Light background for this specific page based on design
    Color backgroundColor = isDark ? Colors.black : const Color(0xFFF5F5F5);

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
                         "Add UPI", // Corrected title from "Add card" design artifact
                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                       ),
                     ),
                   ),
                   const SizedBox(width: 40),
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
                    Text("Select a UPI app", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    Text(
                      "We will make a ₹1 charge request on the selected UPI app to verify your UPI ID.",
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // --- Apps List ---
                    _buildAppItem("PhonePe", Colors.purple, isDark, textColor),
                    const SizedBox(height: 12),
                    _buildAppItem("Google Pay", Colors.blue, isDark, textColor),
                    const SizedBox(height: 12),
                    _buildAppItem("Paytm", Colors.lightBlue, isDark, textColor),
                    const SizedBox(height: 12),
                    _buildAppItem("CRED UPI", Colors.black, isDark, textColor),
                    const SizedBox(height: 12),
                    _buildAppItem("More UPI apps", Colors.amber, isDark, textColor, icon: Icons.grid_view),
                    const SizedBox(height: 12),
                    _buildAppItem("Enter UPI ID manually", Colors.grey, isDark, textColor, icon: Icons.keyboard),
                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppItem(String name, Color color, bool isDark, Color textColor, {IconData? icon}) {
    Color cardColor = isDark ? Colors.grey[850]! : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Logo placeholder
          icon != null 
              ? Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 28)
              : Container(
                width: 28, 
                height: 28, 
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
              ),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor))),
          Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey[600] : Colors.grey[400]),
        ],
      ),
    );
  }
}
