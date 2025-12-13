import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class RidePreviewPage extends StatelessWidget {
  final Map<String, dynamic> bookingDetails;

  const RidePreviewPage({super.key, required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    final vehicle = bookingDetails['vehicle'] as Map<String, dynamic>?;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    Color borderColor = Colors.grey.withOpacity(0.2);
    Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
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
                              "Ride Preview",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // --- Stepper (1 - 2 - 3) ---
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
                  const SizedBox(height: 30),

                  // --- Details Cards ---
                  _buildDetailCard(
                    "Pickup Details", 
                    Icons.location_on_outlined, 
                    bgColor: innerCardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Location: ${bookingDetails['pickup'] ?? ''}", style: TextStyle(color: subTextColor, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text("Date: ${bookingDetails['date'] ?? ''}", style: TextStyle(color: subTextColor, fontSize: 13)),
                        Text("Time: ${bookingDetails['time'] ?? ''}", style: TextStyle(color: subTextColor, fontSize: 13)),
                      ],
                    )
                  ),
                  const SizedBox(height: 16),

                  _buildDetailCard(
                    "Destination", 
                    Icons.location_on_outlined, 
                    bgColor: innerCardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    content: Text("Location: ${bookingDetails['destination'] ?? ''}", style: TextStyle(color: subTextColor, fontSize: 13))
                  ),
                  const SizedBox(height: 16),

                  _buildDetailCard(
                    "Vehicle Selected", 
                    Icons.directions_car_outlined, 
                    bgColor: innerCardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    content: Text("${vehicle?['name'] ?? ''}", style: TextStyle(color: subTextColor, fontSize: 13)),
                    iconColor: Colors.amber
                  ),
                  const SizedBox(height: 16),

                  _buildDetailCard(
                    "Passenger Details", 
                    Icons.person_outline, 
                    bgColor: innerCardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${bookingDetails['passengerName'] ?? ''}", style: TextStyle(color: subTextColor, fontSize: 13)),
                        Text("Phone no: ${bookingDetails['passengerPhone'] ?? ''}", style: TextStyle(color: subTextColor, fontSize: 13)),
                      ],
                    )
                  ),
                  const SizedBox(height: 24),

                  // --- Promo Code ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber.shade900.withOpacity(0.5) : Colors.amber.shade300.withValues(alpha: 0.5), // Adjusted for dark
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.discount_outlined, size: 20, color: textColor),
                            const SizedBox(width: 8),
                            Text("Promo code", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700.withValues(alpha: 0.1), // Darker overlay
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("ENTER COUPON CODE", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text("Apply"),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Pricing Details ---
                  Text("Pricing Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Estimated Distance", style: TextStyle(color: subTextColor)),
                      Text("${vehicle?['dist'] ?? ''}", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Estimated Time", style: TextStyle(color: subTextColor)),
                      Text("${vehicle?['time'] ?? ''}", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text("Bill Summary", style: TextStyle(color: subTextColor)),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_down, color: textColor),
                    ],
                  ),
                   const SizedBox(height: 20),

                   // Book Now Button
                   SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Book Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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

  Widget _buildDetailCard(String title, IconData icon, {required Widget content, Color? iconColor, required Color bgColor, required Color borderColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: content,
          )
        ],
      ),
    );
  }
}
