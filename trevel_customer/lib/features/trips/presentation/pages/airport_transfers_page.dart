import 'package:flutter/material.dart';
import '../../../../shared/widgets/booking_success_dialog.dart';
import '../../../../shared/widgets/booking_error_dialog.dart';
import 'ride_preview_page.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import 'my_bookings_page.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../data/airport_repository.dart';
import '../../data/trips_repository.dart';
import '../../../../core/services/location_service.dart';
import '../../../booking/presentation/widgets/bill_summary_widget.dart';


class AirportTransfersPage extends StatefulWidget {
  const AirportTransfersPage({super.key});

  @override
  State<AirportTransfersPage> createState() => _AirportTransfersPageState();
}

class _AirportTransfersPageState extends State<AirportTransfersPage> {
  int _currentStep = 1;
  int _selectedVehicleIndex = 0; 
  int _travelerType = 0; // 0 = Myself, 1 = Someone else
  bool _isToAirport = true; // Toggle state

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController(); 
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  List<AirportData> _airports = [];
  AirportData? _selectedAirport;
  bool _isLoadingAirports = false;

  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoadingEstimates = false;
  // ignore: unused_field
  bool _isLoadingLocation = false; // Add loading state for location

  @override
  void initState() {
    super.initState();
    _fillUserData();
    _fillUserData();
    // _fetchAirports(); // Removed as per user request
    _fetchEstimates();
  }

  Future<void> _fetchEstimates() async {
    setState(() => _isLoadingEstimates = true);
    // Combine date and time? Or just send time since pricing logic often just needs hour.
    // Backend expects 'pickup_time'. Formatting as HH:mm or Date string.
    // Let's send the time string for now if just hour based, or current time.
    final est = await AirportRepository().getAirportEstimate(
      _isToAirport ? 'drop' : 'pickup',
      _timeController.text.isNotEmpty ? _timeController.text : "12:00 PM",
      userLocation: _pickupController.text,
      terminal: _terminalController.text,
    );
    setState(() {
      _vehicles = est;
      _isLoadingEstimates = false;
      if (_selectedVehicleIndex >= _vehicles.length) _selectedVehicleIndex = 0;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber, 
              onPrimary: Colors.black, 
              onSurface: Colors.black, 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, 
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Format: Dec 03, 2025
      // Simple custom formatting or use intl if available. 
      // Using simple formatting to avoid adding deps if not needed, but intl is better.
      // Assuming intl might not be imported, let's do manual for now or basic toString.
      // Actually standard format in dummy data was "Dec 03,2025".
      // Let's try to match it or use a standard readable format.
      // "2025-12-03" is standard but less pretty.
      // Let's use a basic map for months to match the style.
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String formatted = "${months[picked.month - 1]} ${picked.day.toString().padLeft(2, '0')},${picked.year}";
      setState(() {
        _dateController.text = formatted;
      });
      // Date changed might implies different peak/non-peak if day of week matters (not in current logic but good practice)
      // _fetchEstimates(); 
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    // Current time + 2 hours rule
    final now = DateTime.now();
    final twoHoursLater = now.add(const Duration(hours: 2));
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(twoHoursLater),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber, 
              onPrimary: Colors.black, 
              onSurface: Colors.black, 
            ),
             timePickerTheme: TimePickerThemeData(
              dialHandColor: Colors.amber,
              dialBackgroundColor: Colors.grey[200],
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
       // Validation check
       // We need to check if the selected date is today.
       // Note: _dateController might have formatted text "Dec 03,2025"
       // Simpler check: If today, ensure time is > now + 2h.
       // For now, honestly enforcing it strictly might be complex without robust date parsing.
       // But setting the initial time helps the user.
       // Let's at least show a warning if they pick something too early if possible,
       // or just accept it as they might be booking for tomorrow but haven't changed date yet (UI flow).
       // Actually, common flow is Date -> Time.
       
       setState(() {
        _timeController.text = picked.format(context);
      });
      _fetchEstimates();
    }
  }

  // Airport fetch removed
  // Future<void> _fetchAirports() async { ... }

  void _fillUserData() {
    _nameController.text = "Yash Patel";
    _phoneController.text = "9876543210";
  }

  void _clearUserData() {
    _nameController.clear();
    _phoneController.clear();
  }

  Future<void> _getCurrentLocation(TextEditingController controller) async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        final addressData = await locationService.getAddressFromCoordinates(position.latitude, position.longitude);
        if (addressData != null && addressData['formatted_address'] != null) {
          setState(() {
            controller.text = addressData['formatted_address'];
          });
        }
      } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not fetch location")));
        }
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header ---
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                             if (_currentStep == 1) {
                               Navigator.pop(context);
                             } else if (_currentStep == 3 && _travelerType == 0) {
                               // If 'Myself', back from Step 3 goes to Step 1 (skipping Step 2)
                               setState(() => _currentStep = 1);
                             } else {
                               setState(() => _currentStep--);
                             }
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.amber,
                            radius: 20,
                            child: Icon(Icons.arrow_back, color: Colors.black),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Airport Transfers",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), 
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                     // --- Stepper ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepCircle("1", _currentStep >= 1, isDark),
                        _buildStepLine(),
                        _buildStepCircle("2", _currentStep >= 2, isDark),
                        _buildStepLine(),
                        _buildStepCircle("3", _currentStep >= 3, isDark),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- Content Switcher ---
                    if (_currentStep == 1) 
                      _buildStep1(isDark, textColor, cardColor) 
                    else if (_currentStep == 2) 
                      _buildStep2(isDark, textColor, cardColor)
                    else
                      _buildStep3(isDark, textColor, cardColor),
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
          if (index == 0) Navigator.pop(context);
          if (index == 1) {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsPage()));
          }
        },
      ),
    );
  }

  Widget _buildStep1(bool isDark, Color textColor, Color cardColor) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Toggle: To/From Airport ---
        Container(
          decoration: BoxDecoration(
            color: innerCardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _buildToggleButton("To Airport", _isToAirport, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildToggleButton("From Airport", !_isToAirport, isDark)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Form Fields ---
        Row(
          children: [
            Expanded(child: _buildLabel("Pickup Date", Icons.calendar_today_outlined, textColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildLabel("Pickup Time", Icons.access_time, textColor)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInputBox(
                controller: _dateController, 
                isDark: isDark, 
                textColor: textColor,
                readOnly: true,
                onTap: () => _selectDate(context),
                hint: "Select Date"
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputBox(
                controller: _timeController, 
                icon: Icons.access_time, 
                isDark: isDark, 
                textColor: textColor,
                readOnly: true,
                onTap: () => _selectTime(context),
                hint: "Select Time"
              )
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Conditional Fields based on Toggle
        if (_isToAirport) ...[
          _buildLabel("Pickup Location", Icons.location_on_outlined, textColor),
          const SizedBox(height: 8),
          _buildPlacesAutoComplete(_pickupController, "Enter pickup location", isDark, textColor),

          const SizedBox(height: 20),
          _buildLabel("Airport terminal", Icons.flight_takeoff, textColor),
          const SizedBox(height: 8),
          _buildTerminalDropdown(isDark, textColor),
        ] else ...[
          _buildLabel("Pickup Terminal", Icons.flight_takeoff, textColor),
          const SizedBox(height: 8),
          _buildTerminalDropdown(isDark, textColor),
          
          const SizedBox(height: 20),
          _buildLabel("Destination", Icons.flight_land, textColor),
          const SizedBox(height: 8),
          // Destination is now generic input or address
          _buildPlacesAutoComplete(_pickupController, "Enter your destination", isDark, textColor),
        ],


        const SizedBox(height: 20),
        Text("Select Vehicle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 12),
        
        // --- Vehicle List ---
        if (_isLoadingEstimates)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.amber)))
        else if (_vehicles.isEmpty)
           Center(child: Text("No vehicles available", style: TextStyle(color: textColor)))
        else
        ...List.generate(_vehicles.length, (index) {
          final v = _vehicles[index];
          final isSelected = _selectedVehicleIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedVehicleIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber.shade400 : innerCardColor,
                border: Border.all(color: isSelected ? Colors.amber : Colors.grey.withOpacity(0.2), width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    v['image'], 
                    width: 80, 
                    height: 50, 
                    fit: BoxFit.contain,
                    errorBuilder: (c,e,s) => Icon(Icons.directions_car, size: 40, color: isSelected ? Colors.black54 : Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['name'], style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: isSelected ? Colors.black : (isDark ? Colors.amber.shade400 : Colors.amber.shade700)
                        )),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: isSelected ? Colors.black54 : Colors.grey),
                            Text(" ${v['seats']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black54 : Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: isSelected ? Colors.black54 : Colors.grey),
                            Text(" ${v['time']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black54 : Colors.grey)),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on, size: 14, color: isSelected ? Colors.black54 : Colors.grey),
                            Text(" ${v['dist']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black54 : Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    v['price'],
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : (isDark ? Colors.amber.shade400 : Colors.amber.shade700)
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        
        const SizedBox(height: 10),
        // Proceed to Step 2
        const SizedBox(height: 20),
        Text("Who is travelling ?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildRadioOption("Myself", 0, isDark, textColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildRadioOption("Someone else", 1, isDark, textColor)),
          ],
        ),
        const SizedBox(height: 20),

        // Proceed Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
               if (_dateController.text.isEmpty || _timeController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date and Time")));
                 return;
               }
               // Fetch real estimates now that we have location
               _fetchEstimates();
               
               setState(() {
                 if (_travelerType == 0) {
                   // If 'Myself', skip to Step 3 (Preview)
                   _currentStep = 3;
                 } else {
                   // If 'Someone else', go to Step 2 (Passenger Details)
                   _currentStep = 2;
                 }
               });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text("Confirm Destination", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2(bool isDark, Color textColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle moved to Step 1
        Text("Passenger Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),

        const SizedBox(height: 12),
        // Always show inputs for editing
        _buildLabel("Full Name", Icons.person_outline, textColor),
        const SizedBox(height: 8),
        _buildInputBox(hint: "Enter Full Name", controller: _nameController, isDark: isDark, textColor: textColor),
        
        const SizedBox(height: 20),
        _buildLabel("Phone Number", Icons.phone_outlined, textColor),
        const SizedBox(height: 8),
        _buildInputBox(hint: "Enter Phone Number", controller: _phoneController, isDark: isDark, textColor: textColor),

        const SizedBox(height: 40),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 1; // Go back to Step 1
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.amber),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Back", style: TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter details")));
                      return;
                    }
                    setState(() {
                      _currentStep = 3; // Go to Step 3
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                    elevation: 0,
                  ),
                  child: const Text("Proceed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStep3(bool isDark, Color textColor, Color cardColor) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Pickup Details ---
        _buildReviewCard(
          title: "Pickup Details",
          icon: Icons.location_on_outlined,
          bgColor: innerCardColor,
          textColor: textColor,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isToAirport ? _pickupController.text : _terminalController.text, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
              const SizedBox(height: 12),
              Text("Date: ${_dateController.text}", style: TextStyle(color: subTextColor, fontSize: 13)),
              Text("Time: ${_timeController.text}", style: TextStyle(color: subTextColor, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Destination ---
        _buildReviewCard(
          title: "Destination",
          icon: Icons.location_on_outlined,
          bgColor: innerCardColor,
          textColor: textColor,
          content: Text(_isToAirport ? _terminalController.text : _pickupController.text, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
        ),
        const SizedBox(height: 16),

        // --- Vehicle Selected ---
        _buildReviewCard(
          title: "Vehicle Selected",
          icon: Icons.directions_car_outlined,
          bgColor: innerCardColor,
          textColor: textColor,
          content: Text(_vehicles[_selectedVehicleIndex]['name'], style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
        ),
        const SizedBox(height: 16),

        // --- Passenger Details ---
        _buildReviewCard(
          title: "Passenger Details",
          icon: Icons.person_outline,
          bgColor: innerCardColor,
          textColor: textColor,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${_nameController.text}", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
              Text("Phone no: ${_phoneController.text}", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
            ],
          )
        ),
        const SizedBox(height: 24),

        // --- Promo Code ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.amber.shade900.withOpacity(0.5) : Colors.amber.shade200, 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(children: [
                 Icon(Icons.confirmation_number_outlined, size: 18, color: textColor),
                 const SizedBox(width: 8),
                 Text("Promo code", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
               ]),
               const SizedBox(height: 12),
               Row(
                 children: [
                   Expanded(
                     child: Container(
                       height: 40,
                       padding: const EdgeInsets.symmetric(horizontal: 12),
                       decoration: BoxDecoration(
                         color: Colors.amber.shade700.withValues(alpha: 0.1), 
                         borderRadius: BorderRadius.circular(4),
                       ),
                       alignment: Alignment.centerLeft,
                       child: Text("ENTER COUPON CODE", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Container(
                     height: 40,
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     decoration: BoxDecoration(
                       color: isDark ? Colors.white : Colors.black,
                       borderRadius: BorderRadius.circular(4),
                     ),
                     alignment: Alignment.center,
                     child: Text("Apply", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                   ),
                 ],
               )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Pricing Details ---
        // --- Route Details ---
        _buildReviewCard(
          title: "Route Details",
          icon: Icons.map_outlined,
          bgColor: innerCardColor,
          textColor: textColor,
          content: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text("Distance: ${_vehicles[_selectedVehicleIndex]['dist']}", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
               const SizedBox(height: 4),
               Text("Time: ${_vehicles[_selectedVehicleIndex]['time']}", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
             ],
          )
        ),
        const SizedBox(height: 16),

        // --- Bill Summary ---
        Builder(
          builder: (context) {
             final v = _vehicles[_selectedVehicleIndex];
             // Expecting camelCase from backend for Aiport Estimate
             double base = (v['basePrice'] as num?)?.toDouble() ?? 0.0;
             double tax = (v['gstAmount'] as num?)?.toDouble() ?? 0.0;
             double total = (v['finalPrice'] as num?)?.toDouble() ?? 0.0;
             
             // Fallback if missing
             if (total == 0) {
                 total = double.tryParse(v['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                 base = total; // No breakdown
             }

             return BillSummaryWidget(
               basePrice: base,
               discount: 0, 
               coupon: 0,
               otherCharges: tax,
               totalPrice: total,
             );
          }
        ),
        const SizedBox(height: 16),
        
        // --- Bill Summary Accordion Stub ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Icon(Icons.receipt_long_outlined, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text("Bill Summary", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
            ]),
            Icon(Icons.keyboard_arrow_down, color: textColor),
          ],
        ),

        const SizedBox(height: 30),

        // --- Book Now Button ---
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
               // Validate location fields
               if (_pickupController.text.isEmpty || _terminalController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Please enter pickup location and select terminal"))
                 );
                 return;
               }
               
               // Prepare Booking Data (Mocking some values for now)
               final v = _vehicles[_selectedVehicleIndex];
               // Clean price string "₹799" -> 799.0
               final price = double.tryParse(v['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
               
               final bookingData = {
                 // For "To Airport": pickup is the address, dropoff is terminal
                 // For "From Airport": pickup is terminal, dropoff is the address
                 "pickup_location": _isToAirport ? _pickupController.text : _terminalController.text,
                 "dropoff_location": _isToAirport ? _terminalController.text : _pickupController.text, 
                 "pickup_date": "2025-12-03", // TODO: Real date parsing
                 "pickup_time": _timeController.text,
                 "vehicle_selected": v['name'],
                 "estimated_distance_km": 20.0, // Mock distance
                 "estimated_time_min": v['time'],
                 "base_price": price,
                 "final_price": price,
                 "currency": "INR",
                 "passenger_name": _nameController.text.isNotEmpty ? _nameController.text : "Guest User",
                 "passenger_phone": _phoneController.text.isNotEmpty ? _phoneController.text : "0000000000",
               };

               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking...")));

               // Trigger generic loading or just wait
               final success = await TripsRepository().createBooking(bookingData);

               if (!context.mounted) return;

               if (success) {
                 showDialog(
                   context: context,
                   builder: (context) => BookingSuccessDialog(
                     onContinue: () {
                       Navigator.pop(context); // Close dialog
                       Navigator.pop(context); // Go back to Home
                     },
                   ),
                 );
               } else {
                 showDialog(
                   context: context,
                   builder: (context) => BookingErrorDialog(
                     onClose: () => Navigator.pop(context),
                   ),
                 );
               }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
              elevation: 0,
            ),
            child: const Text("Book Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),

      ],
    );
  }

  Widget _buildReviewCard({required String title, required IconData icon, required Widget content, required Color bgColor, required Color textColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: content,
          ),
        ],
      ),
    );
  }



  Widget _buildToggleButton(String text, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isToAirport = text == "To Airport";
        });
        _fetchEstimates();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : (isDark ? Colors.grey[800] : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: isDark ? Colors.grey[700]! : Colors.black),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black)),
          ),
        ),
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

  Widget _buildLabel(String text, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildInputBox({String? hint, TextEditingController? controller, IconData? icon, Color? iconColor, required bool isDark, required Color textColor, bool readOnly = false, VoidCallback? onTap}) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: innerCardColor,
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          suffixIcon: icon != null ? Icon(icon, size: 20, color: iconColor ?? (isDark ? Colors.grey[400] : Colors.black54)) : null,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildRadioOption(String label, int value, bool isDark, Color textColor) {
    bool isSelected = _travelerType == value;
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return GestureDetector(
      onTap: () {
        setState(() {
          _travelerType = value;
          if (value == 0) {
            _fillUserData();
          } else {
            _clearUserData();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
          color: innerCardColor,
          boxShadow: [
             BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, color: textColor)),
          ],
        ),
      ),
    );
  }
  Widget _buildTerminalDropdown(bool isDark, Color textColor) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    // User requested simplified terminal list "up to 3" without airport names
    List<String> terminals = ["Terminal 1", "Terminal 2", "Terminal 3"];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: innerCardColor,
      ),
      child: DropdownButtonFormField<String>(
        value: _terminalController.text.isNotEmpty && terminals.contains(_terminalController.text)
            ? _terminalController.text 
            : null,
        hint: const Text("Select your terminal", style: TextStyle(color: Colors.grey)),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        isExpanded: true, // Fix overflow
        dropdownColor: innerCardColor,
        icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.grey[400] : Colors.black54),
        style: TextStyle(color: textColor, fontSize: 16),
        items: terminals.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value, 
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: terminals.isEmpty ? null : (newValue) {
          setState(() {
            _terminalController.text = newValue!;
          });
          // Trigger fetch if "To Airport" (Drop is Terminal)
          if (_isToAirport) {
             _fetchEstimates();
          }
        },
      ),
    );
  }

  // Airport Dropdown Widget Removed

  Widget _buildPlacesAutoComplete(TextEditingController controller, String hint, bool isDark, Color textColor, {VoidCallback? onSelectionChanged}) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 2), 
       decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        color: innerCardColor,
        boxShadow: [
           BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
           if (textEditingValue.text.length < 3) {
             return const Iterable<String>.empty();
           }
           return await AirportRepository().getPlacePredictions(textEditingValue.text);
        },
        onSelected: (String selection) {
          controller.text = selection;
          setState(() {});
          if (onSelectionChanged != null) {
            onSelectionChanged();
          }
        },
        fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
            // Keep the initial value in sync if controller has text
            if (controller.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
                fieldTextEditingController.text = controller.text;
            }
            // Bind the internal controller updates to our main controller
            fieldTextEditingController.addListener(() {
              controller.text = fieldTextEditingController.text;
            });

            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.my_location, color: isDark ? Colors.grey[400] : Colors.black54),
                  onPressed: () => _getCurrentLocation(controller),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) {
                  controller.text = val;
              }
            );
        },
        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
           return Align(
             alignment: Alignment.topLeft,
             child: Material(
               elevation: 4.0,
               color: innerCardColor,
               borderRadius: BorderRadius.circular(8),
               child: Container(
                 width: MediaQuery.of(context).size.width - 60, // Adjust width
                 constraints: const BoxConstraints(maxHeight: 200),
                 child: ListView.builder(
                   padding: EdgeInsets.zero,
                   shrinkWrap: true,
                   itemCount: options.length,
                   itemBuilder: (BuildContext context, int index) {
                     final String option = options.elementAt(index);
                     return InkWell(
                       onTap: () {
                         onSelected(option);
                       },
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Text(option, style: TextStyle(color: textColor)),
                       ),
                     );
                   },
                 ),
               ),
             ),
           );
        },
      ),
    );
  }
}
