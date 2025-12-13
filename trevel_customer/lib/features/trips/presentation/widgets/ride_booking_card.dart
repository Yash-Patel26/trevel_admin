import 'package:flutter/material.dart';

class RideBookingCard extends StatelessWidget {
  final String date;
  final String time;
  final String price;
  final String status;
  final Color statusColor;
  final String pickupLocation;
  final String dropLocation;
  final String otp;
  final String vehicleImage;

  const RideBookingCard({
    super.key,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    required this.statusColor,
    required this.pickupLocation,
    required this.dropLocation,
    required this.otp,
    required this.vehicleImage,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color itemColor = isDark ? Colors.grey[850]! : Colors.white;
    Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header: Date & Price/Status ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$date, $time",
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Middle: Route & Image ---
          Row(
            children: [
              // Route Timeline
              Expanded(
                child: Column(
                  children: [
                    _buildLocationRow(Icons.location_on_outlined, pickupLocation, isStart: true, textColor: textColor),
                    Container(
                      margin: const EdgeInsets.only(left: 11),
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid, width: 1)),
                      ),
                    ),
                    _buildLocationRow(Icons.my_location, dropLocation, isStart: false, textColor: textColor),
                  ],
                ),
              ),
              // Car Image
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/car_placeholder.png', 
                width: 100,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) => Container(
                  width: 100,
                  height: 60,
                  color: isDark ? Colors.grey[800] : Colors.grey.shade100,
                  child: const Icon(Icons.directions_car, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 8),

          // --- Footer: OTP & Details ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "OTP: $otp",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              ),
              Row(
                children: [
                  Text("View Details", style: TextStyle(fontSize: 13, color: subTextColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: subTextColor),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text, {required bool isStart, required Color textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isStart ? Colors.amber : Colors.green, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
