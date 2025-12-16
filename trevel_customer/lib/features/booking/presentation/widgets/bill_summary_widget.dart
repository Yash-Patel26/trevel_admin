import 'package:flutter/material.dart';

class BillSummaryWidget extends StatelessWidget {
  final double basePrice;
  final double discount;
  final double coupon;
  final double otherCharges;
  final double totalPrice;

  const BillSummaryWidget({
    super.key,
    required this.basePrice,
    this.discount = 0,
    this.coupon = 0,
    this.otherCharges = 0,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    // Colors based on the screenshot (Grayish background, dark text/light text depending on theme)
    // The screenshot has a dark theme look with a gray card.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Bill Summary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: textColor),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow("Base Price", basePrice, secondaryTextColor),
          const SizedBox(height: 8),
          _buildRow("Discount", discount, secondaryTextColor),
          const SizedBox(height: 8),
          _buildRow("Coupon", coupon, secondaryTextColor, isNegative: true),
          const SizedBox(height: 8),
          _buildRow("Other Charges", otherCharges, secondaryTextColor),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Price",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                "₹ ${totalPrice.toInt()}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, Color? color, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color),
        ),
        Text(
          "${isNegative ? '-' : ''}₹${amount.toInt()}",
          style: TextStyle(fontSize: 14, color: color),
        ),
      ],
    );
  }
}
