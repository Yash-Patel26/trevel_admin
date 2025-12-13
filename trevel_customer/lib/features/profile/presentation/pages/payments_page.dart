import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import 'add_card_page.dart';
import 'upi_selection_page.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;
    
    // Light background for this specific page based on design, or stick to app theme
    Color backgroundColor = isDark ? Colors.black : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header with Back Button
          const CustomAppBar(title: "Payments", showBackButton: true),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text("Wallets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 12),
                  
                  // --- Trevel Cash Card ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Trevel cash", style: TextStyle(fontSize: 16, color: textColor)),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("₹0.00", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text("(+) Add Money", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text("Payment Methods", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 12),

                  // --- Payment Methods List ---
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMethodItem(
                          Icons.credit_card, 
                          "Credit or debit card", 
                          isDark, 
                          textColor, 
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCardPage()));
                          }
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                        _buildMethodItem(Icons.account_balance, "Net banking", isDark, textColor),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                        _buildMethodItem(
                          Icons.qr_code_scanner, 
                          "UPI", 
                          isDark, 
                          textColor,
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const UpiSelectionPage()));
                          }
                        ), // Using QR code icon for UPI as placeholder
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem(IconData icon, String label, bool isDark, Color textColor, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
      title: Text(label, style: TextStyle(fontSize: 16, color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
