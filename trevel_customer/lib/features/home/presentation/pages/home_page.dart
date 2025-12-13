import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../trips/presentation/pages/mini_trips_page.dart';
import '../../../trips/presentation/pages/airport_transfers_page.dart';
import '../../../trips/presentation/pages/hourly_rentals_page.dart';
import '../../../trips/presentation/pages/my_bookings_page.dart';
import '../../../trips/presentation/pages/coming_soon_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black, // Dark background for status bar area etc if visible
      body: Stack(
        children: [
          // 1. Map Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(12.9716, 77.5946), // Bangalore
                zoom: 14.4746,
              ),
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                // Map created
              },
            ),
          ),

          // 2. Custom Top Bar
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomAppBar(),
          ),

          // 3. Content Sheet (DraggableScrollableSheet or just Positioned)
          // Using Positioned with a fixed height/location to match the design roughly
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.12), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar (Optional, purely visual)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Center(
                      child: Text(
                        "Choose your ride",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grid
                    GridView.count(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildRideCard(context, "Airport Transfers", isDark ? 'assets/images/ride-airport-black.png' : 'assets/images/air.png', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AirportTransfersPage()));
                        }),
                        _buildRideCard(context, "Hourly Rentals", isDark ? 'assets/images/mini-black.png' : 'assets/images/mini.png', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HourlyRentalsPage()));
                        }),
                        _buildRideCard(context, "Mini Trips",isDark ? 'assets/images/mini-black.png' : 'assets/images/mini.png', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MiniTripsPage()));
                        }),
                        _buildRideCard(context, "Outstation Rides",isDark ? 'assets/images/ride-outstation-black.png' : 'assets/images/outsation.png', () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const ComingSoonPage()));
                        }),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Promo Banner
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(80),
                                )
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(60),
                                  bottomRight: Radius.circular(16),
                                )
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Align(
                                      widthFactor: 0.7,
                                      child: CircleAvatar(
                                        radius: 12, 
                                        backgroundColor: Colors.grey.shade300, 
                                        child: const Icon(Icons.person, size: 16, color: Colors.black54),
                                      ),
                                    ),
                                    Align(
                                      widthFactor: 0.7,
                                      child: CircleAvatar(
                                        radius: 12, 
                                        backgroundColor: Colors.grey.shade400, 
                                        child: const Icon(Icons.person, size: 16, color: Colors.black54),
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 12, 
                                      backgroundColor: Colors.grey.shade300, 
                                      child: const Icon(Icons.person, size: 16, color: Colors.black54),
                                    ), 
                                  ],
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(color: Colors.amber, fontSize: 12),
                                    children: [
                                      TextSpan(text: "Rides\n", style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: "are nothing\nwithout friends!"),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text("Invite Friends", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 80), 
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
          if (index == 1) {
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

  Widget _buildRideCard(BuildContext context, String title, String imagePath, VoidCallback onTap, {BoxFit fit = BoxFit.contain}) { 
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full Size Image
              Transform.scale(
                scale: 1.2,
                child: Image.asset(
                  imagePath, 
                  fit: fit,
                  errorBuilder: (c,e,s) => Container(color: isDark ? Colors.grey[800] : Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)), 
                ),
              ),
              
              // 2. Gradient Overlay for Text Readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
