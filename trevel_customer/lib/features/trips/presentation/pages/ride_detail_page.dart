import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../data/bookings_repository.dart';

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
      'eta': apiData['estimatedTimeMin']?.toString(),
      'price': '₹${apiData['finalPrice']}',
      'date': _formatDate(apiData['pickupDate']),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
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
        backgroundColor: Colors.black,
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
                         style: TextStyle(color: Colors.white)),
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
      backgroundColor: Colors.black,
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

          // --- Driver Information ---
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

          // --- Ride Status & Details ---
          Text("Ride Status & Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
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
                _buildCompactDetailRow("ETA", _bookingDetails!['eta'] ?? "Calculating...", textColor),
                const SizedBox(height: 8),
                _buildCompactDetailRow("Cost", _bookingDetails!['price'] ?? "₹0", textColor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Status", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isInProgress ? Colors.lightBlueAccent : Colors.amber, 
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isInProgress ? "IN_PROGRESS" : "ASSIGNED", 
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text("Share Live Ride", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Vehicle Info
                _buildCompactDetailRow("Vehicle", _bookingDetails!['vehicleModel'] ?? "Not assigned", textColor),
                const SizedBox(height: 8),
                _buildCompactDetailRow("Vehicle Number", _bookingDetails!['vehicleNumber'] ?? "Not assigned", textColor),
                const SizedBox(height: 8),
                _buildCompactDetailRow("Date", _bookingDetails!['date'] ?? "N/A", textColor),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    Text(_bookingDetails!['price'] ?? "₹0", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
    return Column(
      children: [
        Container(
          height: 220,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            image: const DecorationImage(
              image: AssetImage('assets/images/map_placeholder.png'),
              fit: BoxFit.cover,
            )
          ),
          child: Stack(
            children: [
              if (true) ...[
                 const Center(child: Icon(Icons.map, size: 60, color: Colors.black12)),
                 const Positioned(
                   top: 60, right: 80,
                   child: Icon(Icons.location_on, color: Colors.green, size: 40),
                 ),
                 Positioned(
                   top: 50, right: 80,
                   child: SizedBox(
                     width: 100,
                     height: 100,
                     child: CustomPaint(
                       painter: RoutePainter(),
                     ),
                   )
                 ),
              ]
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_bookingDetails!['pickupLocation'] ?? "Pickup location", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                      const SizedBox(height: 4),
                    ],
                  ),
                  const Spacer(),
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
                         Text(_bookingDetails!['date'] ?? "Friday, Dec 05,2025", style: TextStyle(color: textColor)),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Row(
                       children: [
                         const Icon(Icons.access_time, size: 16, color: Colors.grey),
                         const SizedBox(width: 8),
                         Text("10:23 AM", style: TextStyle(color: textColor)),
                       ],
                     ),
                   ],
                 ),
                 Text(_bookingDetails!['price'] ?? "₹320", style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
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
                _buildFareRow("Base Fare", "₹320", textColor),
                _buildFareRow("Tax & Fees", "₹0", textColor),
                _buildFareRow("Tip", "₹0", textColor),
                Divider(height: 24, color: Colors.grey.shade200),
                _buildFareRow("Total", "₹320", textColor, isTotal: true),
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



