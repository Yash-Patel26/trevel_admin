import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../data/bookings_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'fullscreen_map_page.dart';
import '../../../../core/services/directions_service.dart';
import '../../domain/entities/route_details.dart';

class RideDetailPage extends StatefulWidget {
  final String bookingId; // Changed from bookingDetails to bookingId

  const RideDetailPage({super.key, required this.bookingId});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  int _selectedTab = 0; // 0: Map, 1: Live cam
  bool _isLoading = true;
  Map<String, dynamic>? _bookingDetails;
  String? _error;

  final BookingsRepository _bookingsRepo = BookingsRepository();
  final DirectionsService _directionsService = DirectionsService();
  
  RouteDetails? _routeDetails;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _bookingsRepo.getBookingDetails(widget.bookingId);
      
      if (details != null) {
        setState(() {
          _bookingDetails = _formatBookingDetails(details);
          _isLoading = false;
        });
        // Fetch route after booking details are loaded
        _fetchRoute();
      } else {
        setState(() {
          _error = "Booking not found";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load booking details";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_bookingDetails == null) return;
    
    final pickup = _bookingDetails!['pickupLocation'];
    final dropoff = _bookingDetails!['destinationLocation'];
    
    if (pickup == null || dropoff == null) return;
    
    setState(() => _isLoadingRoute = true);
    
    try {
      final routeDetails = await _directionsService.getRoute(pickup, dropoff);
      if (mounted) {
        setState(() {
          _routeDetails = routeDetails;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      print('Route fetch error: $e');
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  /// Format API response to match expected structure
  Map<String, dynamic> _formatBookingDetails(Map<String, dynamic> apiData) {
    final driver = apiData['driver'] as Map<String, dynamic>?;
    final vehicle = apiData['vehicle'] as Map<String, dynamic>?;

    return {
      'status': apiData['status'] ?? 'PENDING',
      'driverName': driver?['name'],
      'driverPhone': driver?['mobile'],
      'driverRating': driver?['rating']?.toString(),
      'vehicleModel': vehicle?['model'],
      'vehicleNumber': vehicle?['licensePlate'],
      'pickupLocation': apiData['pickupLocation'],
      'destinationLocation': apiData['destinationLocation'],
      'distance': apiData['estimatedDistanceKm'] != null 
          ? '${apiData['estimatedDistanceKm']} km' 
          : null,
      'eta': _formatTime(apiData['pickupTime']),
      'estimatedTime': apiData['estimatedTimeMin']?.toString(),
      'price': '₹${apiData['finalPrice']}',
      'date': _formatDate(apiData['pickupDate']),
      'pickupTime': _formatTime(apiData['pickupTime']),
      'otp': '----', // OTP would come from a separate field if implemented
    };
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${_getMonthName(dt.month)} ${dt.day}, ${dt.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'N/A';
    try {
      // If it's an ISO time string like "1970-01-01T23:53:00.000Z"
      if (time.toString().contains('T')) {
        final dt = DateTime.parse(time.toString());
        final hour = dt.hour;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return time.toString();
    } catch (e) {
      return time.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            const CustomAppBar(showBackButton: false),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null || _bookingDetails == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            const CustomAppBar(showBackButton: false),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(_error ?? "Failed to load booking", 
                         style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchBookingDetails,
                      child: Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    bool isCompleted = _bookingDetails!['status'] == 'COMPLETED';
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              child: isCompleted ? _buildCompletedView(context) : _buildLiveView(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: 1, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => const HomePage()), 
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

  Widget _buildLiveView(BuildContext context) {
    bool isInProgress = _bookingDetails!['status'] == 'IN_PROGRESS';
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header with Back Button ---
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    "Ride Details",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Tabs & Map Section ---
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(16),
              color: innerCardColor,
              boxShadow: [
                 BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTab("Map", 0, isDark)),
                    Expanded(child: _buildTab("Live cam", 1, isDark)),
                  ],
                ),
                Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                _selectedTab == 0 ? _buildMapContent(context) : SizedBox(height: 300, child: Center(child: Text("Live feed unavailable", style: TextStyle(color: textColor)))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Driver Arrived (Only for IN_PROGRESS) ---
          if (isInProgress) ...[
             Text("Driver Arrived", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
             const SizedBox(height: 12),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey.withOpacity(0.2)),
                 borderRadius: BorderRadius.circular(16),
                 color: innerCardColor,
                 boxShadow: [
                   BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                 ]
               ),
               child: Column(
                 children: [
                   Text("15:00", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: textColor)),
                   Text("(waiting time left)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                   const SizedBox(height: 12),
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           "After 15 minutes, waiting charges will apply at ₹50 per 5 minutes.",
                           style: TextStyle(fontSize: 12, color: textColor),
                         ),
                       ),
                     ],
                   )
                 ],
               ),
             ),
             const SizedBox(height: 24),
          ],


          // --- Driver Information (only show if not PENDING) ---
          if (_bookingDetails!['status']?.toString().toUpperCase() != 'PENDING') ...[
            Text("Driver Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
                color: innerCardColor,
                boxShadow: [
                   BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset:const Offset(0, 2))
                ]
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: const AssetImage('assets/images/user_avatar.jpeg'),
                        child: const Icon(Icons.person, size: 30, color: Colors.white), 
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_bookingDetails!['driverName'] ?? "Driver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                const SizedBox(width: 6),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(" (${_bookingDetails!['driverRating'] ?? 'N/A'})", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_bookingDetails!['driverPhone'] ?? "Not available", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      CircleAvatar(radius: 18, backgroundColor: Colors.amber, child: const Icon(Icons.call, size: 18, color: Colors.black)),
                      const SizedBox(width: 12),
                      CircleAvatar(radius: 18, backgroundColor: Colors.black, child: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Ride OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                      Text(_bookingDetails!['otp'] ?? "----", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // --- Pricing Details (Matching Screenshot) ---
          Text("Pricing Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: textColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.1)), // Lighter border
              borderRadius: BorderRadius.circular(12), // Slightly less rounded than 16
              color: innerCardColor,
              boxShadow: [
                 BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset:const Offset(0, 2))
              ]
            ),
            child: Column(
              children: [
                // Row 1: Estimated Distance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Estimated Distance", style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.normal)),
                    Text(_bookingDetails!['distance'] != null ? "${_bookingDetails!['distance'].toString().replaceAll(" km", "")} kms" : "0 kms", // Formatting to match "20.6 kms"
                         style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Row 2: Estimated Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Estimated Time", style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.normal)),
                     // Parse duration/time more robustly if needed
                    Text(_routeDetails?.duration != null ? "${_routeDetails!.duration.replaceAll(" mins", "")} mins" : (_bookingDetails!['estimatedTime'] != null ? "${_bookingDetails!['estimatedTime']} mins" : "25 mins"), 
                         style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15, color: textColor)),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Bill Summary Header (Accordion style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text("Bill Summary", style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.grey),
                 const SizedBox(height: 16),
                
                // Total Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Price", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    Text(_bookingDetails!['price'] ?? "₹ 0", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMapContent(BuildContext context) {
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    
    // Use route coordinates if available, otherwise use default
    final bool hasRoute = _routeDetails != null && _routeDetails!.polylinePoints.isNotEmpty;
    final LatLng pickupLatLng = hasRoute
        ? _routeDetails!.polylinePoints.first 
        : const LatLng(28.6139, 77.2090);
    final LatLng dropLatLng = hasRoute
        ? _routeDetails!.polylinePoints.last 
        : const LatLng(28.6500, 77.2300);
    
    // Create markers for pickup and drop
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: dropLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop Location'),
      ),
    };
    
    // Create polyline for route - use actual route if available
    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: hasRoute ? _routeDetails!.polylinePoints : [pickupLatLng, dropLatLng],
        color: _getTrafficColor(_routeDetails?.trafficStatus),
        width: 5,
        // Remove dashed pattern for actual routes to show solid line
        patterns: hasRoute ? [] : [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
    
    return Column(
      children: [
        Container(
          height: 300,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(28.6320, 77.2195), // Center between pickup and drop
                    zoom: 12,
                  ),
                  markers: markers,
                  polylines: polylines,
                ),
              ),
              // Zoom/Fullscreen button
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullscreenMapPage(
                            initialPosition: const LatLng(28.6320, 77.2195),
                            markers: markers,
                            polylines: polylines,
                            routeCoordinates: _routeDetails?.polylinePoints ?? [],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_routeDetails != null)
           Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _getTrafficColor(_routeDetails!.trafficStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getTrafficColor(_routeDetails!.trafficStatus).withOpacity(0.3))
              ),
              child: Row(
                  children: [
                      Icon(Icons.traffic, color: _getTrafficColor(_routeDetails!.trafficStatus), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "Traffic: ${_routeDetails!.trafficStatus} (${_routeDetails!.durationInTraffic})",
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                              ),
                          ),
                      ),
                      if (_routeDetails!.trafficDelayMins > 0)
                          Text(
                              "+${_routeDetails!.trafficDelayMins} min",
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          )
                  ],
              ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.amber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bookingDetails!['pickupLocation'] ?? "Pickup location", 
                          style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_bookingDetails!['distance'] ?? "Calculating...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 11),
                height: 20,
                width: 1,
                child: Column(
                  children: List.generate(4, (index) => Expanded(child: Container(width: 1, color: index % 2 == 0 ? Colors.grey : Colors.transparent))),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.my_location, color: Colors.green, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_bookingDetails!['destinationLocation'] ?? "Destination", style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTab(String label, int index, bool isDark) {
     bool isSelected = _selectedTab == index;
     return GestureDetector(
       onTap: () => setState(() => _selectedTab = index),
       child: Container(
         padding: const EdgeInsets.symmetric(vertical: 14),
         decoration: BoxDecoration(
           border: isSelected ? const Border(bottom: BorderSide(color: Colors.amber, width: 3)) : null,
         ),
         child: Text(
           label,
           textAlign: TextAlign.center,
           style: TextStyle(
             fontSize: 16,
             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
             color: isSelected ? Colors.amber : (isDark ? Colors.white : Colors.black),
           ),
         ),
       ),
     );
  }

  Widget _buildCompactDetailRow(String label, String value, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
      ],
    );
  }
  
  Widget _buildCompletedView(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(height: 8),
                Text("Ride completed successfully", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Trip Details", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
              color: innerCardColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                           const SizedBox(width: 8),
                           Text(_bookingDetails!['date'] ?? "N/A", style: TextStyle(color: textColor)),
                         ],
                       ),
                       const SizedBox(height: 8),
                       Row(
                         children: [
                           const Icon(Icons.access_time, size: 16, color: Colors.grey),
                           const SizedBox(width: 8),
                           Text(_bookingDetails!['eta'] ?? "N/A", style: TextStyle(color: textColor)), // Using ETA as proxy for time if not available
                         ],
                       ),
                     ],
                   ),
                   Text(_bookingDetails!['price'] ?? "₹0", style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Route", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Container(
             decoration: BoxDecoration(
               border: Border.all(color: Colors.grey.withOpacity(0.2)),
               borderRadius: BorderRadius.circular(12),
               color: innerCardColor,
             ),
             child: Column(
               children: [
                 Container(
                   height: 150,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: Colors.green.shade50,
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                   ),
                   child: Stack(
                     children: [
                       Center(child: Icon(Icons.map, size: 40, color: Colors.green.shade200)),
                       const Positioned(
                         top: 40, left: 150,
                         child: Icon(Icons.location_on, color: Colors.green, size: 30),
                       )
                     ],
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(16),
                   child: Column(
                     children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(_bookingDetails!['pickupLocation'] ?? "Pickup location", style: TextStyle(fontSize: 13, color: textColor)),
                              ],
                            ),
                            Text(_bookingDetails!['distance'] ?? "N/A", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ),
                        const SizedBox(height: 12),
                         Row(
                          children: [
                            Icon(Icons.my_location, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text(_bookingDetails!['destinationLocation'] ?? "Destination", style: TextStyle(fontSize: 12, color: Colors.grey))),
                          ],
                        ),
                     ],
                   ),
                 ),
               ],
             ),
          ),
          const SizedBox(height: 20),
          Text("Driver Information", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          _buildDriverInfoCardCompleted(innerCardColor, textColor),
          const SizedBox(height: 20),
          Text("Fare Breakdown", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
              color: innerCardColor,
            ),
            child: Column(
              children: [
                _buildFareRow("Base Fare", _bookingDetails!['price'] ?? "₹0", textColor),
                _buildFareRow("Tax & Fees", "₹0", textColor),
                _buildFareRow("Tip", "₹0", textColor),
                Divider(height: 24, color: Colors.grey.shade200),
                _buildFareRow("Total", _bookingDetails!['price'] ?? "₹0", textColor, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Payment", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
              color: innerCardColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.black54, size: 20),
                    const SizedBox(width: 8),
                    Text("Payment Method", style: TextStyle(fontSize: 13, color: textColor)),
                  ],
                ),
                Text("Visa ****4567", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: textColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Download PDF Recipt", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCardCompleted(Color cardColor, Color textColor) {
    return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
                color: cardColor,
              ),
              child: Column(
                children: [
                   Row(
                     children: [
                       CircleAvatar(
                         radius: 24,
                         backgroundColor: Colors.indigo.shade100, 
                         child: const Icon(Icons.person, color: Colors.indigo), 
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Text(_bookingDetails!['driverName'] ?? "Driver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                 const SizedBox(width: 4),
                                 const Icon(Icons.star, color: Colors.amber, size: 16),
                                 Text(" (${_bookingDetails!['driverRating'] ?? 'N/A'})", style: TextStyle(fontSize: 12, color: Colors.grey)),
                               ],
                             ),
                             Text(_bookingDetails!['driverPhone'] ?? "Not available", style: TextStyle(fontSize: 12, color: Colors.grey)),
                           ],
                         ),
                       ),
                       CircleAvatar(radius: 18, backgroundColor: Colors.amber, child: const Icon(Icons.call, size: 18, color: Colors.black)),
                       const SizedBox(width: 8),
                       CircleAvatar(radius: 18, backgroundColor: Colors.black, child: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white)),
                     ],
                   ),
                ],
              ),
             );
  }

  Widget _buildFareRow(String label, String value, Color textColor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? textColor : Colors.grey[600], fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: textColor, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
  Color _getTrafficColor(String? status) {
    if (status == null) return Colors.blue;
    switch (status) {
      case 'Heavy': return Colors.red;
      case 'Moderate': return Colors.orange;
      case 'Normal': 
      default: return Colors.blue;
    }
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width, 0);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



