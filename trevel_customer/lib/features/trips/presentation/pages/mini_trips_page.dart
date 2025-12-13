import 'package:flutter/material.dart';
import '../../../../shared/widgets/booking_success_dialog.dart';
import '../../../../shared/widgets/booking_error_dialog.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../data/trips_repository.dart';
import 'my_bookings_page.dart';

class MiniTripsPage extends StatefulWidget {
  const MiniTripsPage({super.key});

  @override
  State<MiniTripsPage> createState() => _MiniTripsPageState();
}

class _MiniTripsPageState extends State<MiniTripsPage> {
  int _currentStep = 1; 
  int _selectedVehicleIndex = 0; 
  int _travelerType = 0; 
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Vehicle options - fetched from backend
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final data = await TripsRepository().getMiniTripInfo();
    if (data != null && data['vehicles'] != null) {
      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(data['vehicles']);
        // Initialize default fields for UI
        for (var v in _vehicles) {
          v['time'] = "Calculating...";
          v['dist'] = "0 kms";
          v['price'] = "₹0";
        }
        _isLoading = false;
      });
    } else {
        setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // TODO: Implement with actual user data from AuthRepository
  void _fillUserData() {
    // Pre-fill name and phone from authenticated user
    // _nameController.text = currentUser.name;
    // _phoneController.text = currentUser.phone;
  }

  void _clearUserData() {
    _nameController.clear();
    _phoneController.clear();
  }

  Future<bool> _estimateTrip() async {
    final data = await TripsRepository().estimateMiniTrip(
        _pickupController.text, 
        _destinationController.text
    );

    if (data != null) {
        final distKm = (data['distance_km'] as num).toDouble();
        final durationMin = (data['duration_min'] as num).toInt();
        final basePrice = (data['base_price'] as num).toDouble();
        
        setState(() {
            for (var v in _vehicles) {
                double multiplier = (v['priceMultiplier'] as num?)?.toDouble() ?? 1.0;
                double finalPrice = basePrice * multiplier;
                
                v['dist'] = "$distKm km";
                v['time'] = "$durationMin min";
                v['price'] = "₹${finalPrice.toInt()}";
                v['raw_price'] = finalPrice; // Store for booking
            }
        });
        return true;
    }
    return false;
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
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      extendBody: true,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const SizedBox(height: 8),
                    
                    // --- Header Row ---
                    Row(
                      children: [
                        InkWell(
                           onTap: () {
                             if (_currentStep == 1) {
                               Navigator.pop(context);
                             } else if (_currentStep == 3 && _travelerType == 0) {
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
                              "Mini Trips",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                      _buildStep1(isDark, textColor) 
                    else if (_currentStep == 2) 
                      _buildStep2(isDark, textColor)
                    else
                      _buildStep3(isDark, textColor),
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

  Widget _buildStep1(bool isDark, Color textColor) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Pickup Date & Time ---
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
            Expanded(child: _buildInputBox(
              controller: _dateController, 
              isDark: isDark, 
              textColor: textColor,
              readOnly: true,
              onTap: () => _selectDate(context),
              icon: Icons.calendar_today,
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildInputBox(
              controller: _timeController, 
              icon: Icons.access_time, 
              isDark: isDark, 
              textColor: textColor,
              readOnly: true,
              onTap: () => _selectTime(context),
            )),
          ],
        ),
        
        const SizedBox(height: 20),
        _buildLabel("Pickup Location", Icons.location_on_outlined, textColor),
        const SizedBox(height: 8),
        _buildInputBox(controller: _pickupController, isDark: isDark, textColor: textColor),

        const SizedBox(height: 20),
        _buildLabel("Destination", Icons.location_on_outlined, textColor),
        const SizedBox(height: 8),
        _buildInputBox(controller: _destinationController, icon: Icons.my_location, iconColor: Colors.green, isDark: isDark, textColor: textColor),

        const SizedBox(height: 24),
        Text("Select Vehicle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 12),
        
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
                          fontSize: 16,
                          color: isSelected ? Colors.black : (isDark ? Colors.amber.shade400 : Colors.amber.shade700)
                        )),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: isSelected ? Colors.black87 : Colors.grey),
                            Text(" ${v['seats']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: isSelected ? Colors.black87 : Colors.grey),
                            Text(" ${v['time']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey)),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on, size: 14, color: isSelected ? Colors.black87 : Colors.grey),
                            Text(" ${v['dist']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    v['price'],
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : (isDark ? Colors.amber.shade400 : Colors.amber.shade400)
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        
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

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              if (_pickupController.text.isEmpty || _destinationController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter pickup and destination")));
                 return;
              }

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calculating route...")));
              final success = await _estimateTrip();
              
              if (!success) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to estimate trip. Please try again.")));
                 return;
              }

              setState(() {
                if (_travelerType == 0) {
                  _currentStep = 3;
                } else {
                  _currentStep = 2;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
              elevation: 0,
            ),
            child: const Text("Confirm Destination", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Passenger Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 8),
        _buildInputBox(hint: "Enter Full Name", controller: _nameController, isDark: isDark, textColor: textColor),
        
        const SizedBox(height: 20),
        
        _buildLabel("Phone Number", Icons.phone_outlined, textColor),
        const SizedBox(height: 8),
        _buildInputBox(hint: "Enter phone number", controller: _phoneController, isDark: isDark, textColor: textColor),

        const SizedBox(height: 40),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
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
                      _currentStep = 3;
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

  Widget _buildStep3(bool isDark, Color textColor) {
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
              Text(_pickupController.text, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
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
          content: Text(_destinationController.text, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
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

        // --- Pricing Details ---
        Text("Pricing Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        _buildPriceRow("Estimated Distance", _vehicles[_selectedVehicleIndex]['dist'], textColor, subTextColor),
        const SizedBox(height: 8),
        _buildPriceRow("Estimated Time", _vehicles[_selectedVehicleIndex]['time'], textColor, subTextColor),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.withOpacity(0.2)),
        const SizedBox(height: 8),
        
        // --- Book Now Button ---
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
               // Prepare Booking Data
               final v = _vehicles[_selectedVehicleIndex];
               final price = v['raw_price'] as double? ?? 0.0;
               final distStr = v['dist'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
               final dist = double.tryParse(distStr) ?? 0.0;
               final timeStr = v['time'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
               // time is string in backend for estimated_time_min, usually? schema says string. "Minutes or HH:mm"
               
               final bookingData = {
                 "pickup_location": _pickupController.text,
                 "dropoff_location": _destinationController.text,
                 "pickup_date": _dateController.text, 
                 "pickup_time": _timeController.text,
                 "vehicle_selected": v['name'],
                 "vehicle_image_url": v['image'],
                 "estimated_distance_km": dist,
                 "estimated_time_min": v['time'],
                 "base_price": price, // Approximation
                 "final_price": price,
                 "currency": "INR",
                 "passenger_name": _nameController.text,
                 "passenger_phone": _phoneController.text,
                 "notes": ""
               };

               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking...")));

               // Using createHourlyBooking as a placeholder for generic booking creation if createBooking isn't suitable,
               // BUT wait, createHourlyBooking hits `/hourly-rental/bookings`.
               // I need a method for Mini Trip bookings.
               // accessing ApiConstants.miniTripBook?
               // I haven't added `miniTripBook` to ApiConstants or a method to repo.
               // I should have checked that.
               
               // For now, I will assume I need to add that method.
               // I'll call `createMiniTripBooking` which I will add in next step.
               
               final success = await TripsRepository().createMiniTripBooking(bookingData);

               if (success && context.mounted) {
               showDialog(
                 context: context,
                 builder: (context) => BookingSuccessDialog(
                   onContinue: () {
                     Navigator.pop(context); // Close dialog
                     Navigator.pop(context); // Go back to Home
                   },
                 ),
               );
               } else if (context.mounted) {
                 showDialog(
                   context: context,
                   builder: (context) => BookingErrorDialog(
                     message: "Failed to create booking",
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

  Widget _buildPriceRow(String label, String value, Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
      ],
    );
  }

  Widget _buildStepCircle(String text, bool isFilled, bool isDark) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isFilled ? Colors.amber : (isDark ? Colors.transparent : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isFilled ? Colors.white : Colors.amber, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 50, // Slightly longer
      height: 2,
      color: Colors.amber,
    );
  }

  Widget _buildLabel(String text, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)), // Slightly smaller label
      ],
    );
  }

  Widget _buildInputBox({String? hint, TextEditingController? controller, IconData? icon, Color? iconColor, required bool isDark, required Color textColor, bool readOnly = false, VoidCallback? onTap}) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: innerCardColor,
        ),
        child: TextField(
          controller: controller,
          enabled: !readOnly, 
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            suffixIcon: icon != null ? Icon(icon, size: 20, color: iconColor ?? (isDark ? Colors.grey[400] : Colors.black54)) : null,
            hintStyle: const TextStyle(color: Colors.grey),
            isDense: true, 
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
          ],
        ),
      ),
    );
  }
}
