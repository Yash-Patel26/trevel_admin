import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../widgets/ride_booking_card.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/trips_repository.dart'; // Import Repository
import 'ride_detail_page.dart'; // For navigation back home
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  int _selectedTab = 0; // 0: Upcoming, 1: Completed, 2: Cancelled
  bool _isLoading = true;
  List<dynamic> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });
    final bookings = await TripsRepository().getBookings();
    print("Fetched bookings: $bookings");
    if (mounted) {
      setState(() {
        _allBookings = bookings ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // --- Header ---
          const CustomAppBar(
            showBackButton: false, 
          ),
          
          Expanded(
            child: Container(
              width: double.infinity, // Ensure full width
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- Tabs ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _buildTab("Upcoming", 0, Colors.amber, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTab("Completed", 1, Colors.green, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTab("Cancelled", 2, Colors.red, isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- List ---
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                      : _buildRideList(_selectedTab),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 1, // Trips Tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
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

  Widget _buildTab(String label, int index, Color color, bool isDark) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color : (isDark ? Colors.transparent : Colors.white),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? (index == 0 ? Colors.black : Colors.white) : color,
          ),
        ),
      ),
    );
  }

  Widget _buildRideList(int tabIndex) {
    // Safety check
    // ignore: unnecessary_null_comparison
    if (_allBookings == null) {
      _allBookings = [];
    }

    // Filter bookings based on tab
    List<dynamic> filteredBookings = _allBookings.where((booking) {
      String status = (booking['status'] ?? "").toUpperCase();
      if (tabIndex == 0) {
        // Upcoming: PENDING, CONFIRMED, ASSIGNED, STARTED, SEARCHING
        return ["PENDING", "CONFIRMED", "ASSIGNED", "STARTED", "SEARCHING"].contains(status);
      } else if (tabIndex == 1) {
        // Completed
        return status == "COMPLETED";
      } else {
        // Cancelled
        return ["CANCELLED", "CANCEL"].contains(status);
      }
    }).toList();

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No bookings found", 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.amber,
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          return _buildBookingCard(context, booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, dynamic booking) {
    String status = (booking['status'] ?? "UNKNOWN").toUpperCase();
    Color statusColor = Colors.grey;
    if (status == "COMPLETED") statusColor = Colors.green;
    else if (status == "CANCELLED" || status == "CANCEL") statusColor = Colors.red;
    else if (status == "ASSIGNED" || status == "STARTED") statusColor = Colors.amber;
    else if (status == "SEARCHING" || status == "PENDING" || status == "CONFIRMED") statusColor = Colors.lightBlueAccent;

    // Parse Date & Time
    String dateStr = booking['pickup_date'] ?? "";
    String timeStr = booking['pickup_time'] ?? "";
    
    // Attempt basic formatting if date resembles ISO
    if (dateStr.contains('T')) {
       try {
         final dt = DateTime.parse(dateStr);
         // Format roughly as "Mon, 5 Dec"
         const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
         dateStr = "${months[dt.month - 1]} ${dt.day}";
       } catch (_) {}
    }

    String displayDate = "$dateStr, $timeStr";

    return GestureDetector(
      onTap: () {
         if (booking['id'] != null) {
           Navigator.push(
             context, 
             MaterialPageRoute(
               builder: (context) => RideDetailPage(bookingId: booking['id'].toString())
             )
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking ID not available")));
         }
      },
      child: RideBookingCard(
       date: displayDate,
       time: "", 
       price: "₹${booking['final_price'] ?? booking['base_price'] ?? 0}",
       status: status,
       statusColor: statusColor, 
       pickupLocation: booking['pickup_location'] ?? booking['pickup_city'] ?? "Unknown",
       dropLocation: booking['dropoff_location'] ?? booking['destination_location'] ?? booking['destination_city'] ?? "Unknown",
       otp: booking['otp'] ?? "", 
       vehicleImage: "", 
      ),
    );
  }
}
