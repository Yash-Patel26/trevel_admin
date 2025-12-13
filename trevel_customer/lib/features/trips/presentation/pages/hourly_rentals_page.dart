import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/booking_success_dialog.dart';
import '../../../../shared/widgets/booking_error_dialog.dart';
import 'my_bookings_page.dart';
import '../../data/trips_repository.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../../core/constants/api_constants.dart'; // Ensure this path is correct or adjust

class HourlyRentalsPage extends StatefulWidget {
  const HourlyRentalsPage({super.key});

  @override
  State<HourlyRentalsPage> createState() => _HourlyRentalsPageState();
}

class _HourlyRentalsPageState extends State<HourlyRentalsPage> {
  int _currentStep = 1; 
  int _selectedVehicleIndex = 0; 
  int _travelerType = 0; // 0 = Myself, 1 = Someone else
  double _rentingHours = 2.0;

  final TextEditingController _pickupController = TextEditingController(text: "Enter your pickup location");
  final TextEditingController _dateController = TextEditingController(); // formatted string
  final TextEditingController _timeController = TextEditingController(); // formatted string
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Data fetching state
  bool _isLoading = true;
  List<dynamic> _vehicles = [];
  Map<String, dynamic> _pricing = {};

  // For validation and logic
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fillUserData();
    _fetchData();
    
    // Set default date/time (now + 2h buffer) for initial display
    final now = DateTime.now().add(const Duration(hours: 2));
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
    _dateController.text = _formatDate(now);
    _timeController.text = _formatTime(TimeOfDay.fromDateTime(now));
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await TripsRepository().getHourlyRentalInfo();
    if (mounted) {
      if (data != null) {
        setState(() {
          _vehicles = data['vehicles'] ?? [];
          _pricing = data['pricing'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load rental info")));
      }
    }
  }

  void _fillUserData() {
    if (_travelerType == 0) {
      _nameController.text = "Yash Patel";
      _phoneController.text = "9876543210";
    }
  }

  void _clearUserData() {
    _nameController.clear();
    _phoneController.clear();
  }

  // Helper for date formatting (manual to avoid intl dependency if not present)
  String _formatDate(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')},${date.year}";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:${time.minute.toString().padLeft(2, '0')} $period";
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
         _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
      // Re-validate time if date changed to today
      if (_isToday(picked) && _selectedTime != null) {
         _validateTime(_selectedTime!);
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
       builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.amber, onPrimary: Colors.black, onSurface: Colors.black),
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
      _validateTime(picked);
    }
  }

  void _validateTime(TimeOfDay picked) {
    if (_selectedDate != null && _isToday(_selectedDate!)) {
      final now = DateTime.now();
      final pickedDateTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      // 2 hour buffer
      if (pickedDateTime.isBefore(now.add(const Duration(hours: 2)))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a time at least 2 hours from now")));
        // Auto adjust or just keep old? Let's keep old or set to min.
        // For now, warn and don't update if strict, or update and warn.
        // Let's enforce: don't update.
        return;
      }
    }
    
    setState(() {
      _selectedTime = picked;
      _timeController.text = _formatTime(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black, // Dark background for top area
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
                              "Hourly Rentals",
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
                    if (_isLoading)
                       const Center(child: CircularProgressIndicator(color: Colors.amber))
                    else if (_currentStep == 1) 
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
        // --- Date & Time ---
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

        // --- Renting Hours Slider ---
        Row(
          children: [
             const Icon(Icons.access_time, color: Colors.amber, size: 20),
             const SizedBox(width: 8),
             Text(
               "Select Renting Hours (${_rentingHours.toInt()} hrs)", 
               style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)
             ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            thumbColor: Colors.amber,
            trackHeight: 4.0,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Slider(
            value: _rentingHours,
            min: 1,
            max: 12,
            divisions: 11,
            onChanged: (value) {
              setState(() {
                _rentingHours = value;
              });
            },
          ),
        ),
        
        // Show base price for selected hours (assuming first vehicle selected or generic)
        // With slider change, usually we want to see price change. 
        // We will show the price for the CURRENTLY selected vehicle, or a "starts from" price.
        // Let's show currently selected vehicle price.
        Center(
          child: Text(
            "Package Price: ₹${_calculatePrice()}", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)
          )
        ),


        const SizedBox(height: 20),
        _buildLabel("Pickup Location", Icons.location_on_outlined, textColor),
        const SizedBox(height: 8),
        
        // Places Autocomplete integration validation
        // Using simple text field for now unless places usage is required again (it's in imports).
        // Original code had _buildInputBox for pickup location with manual controller.
        // Airport transfer used _buildPlacesAutoComplete. 
        // Let's use simple input for consistency with previous file state unless explicitly asked to upgrade to autocomplete here too.
        // The user request said "in the hourly rental the screen is using the dummy data make it to use real data...".
        // It didn't explicitly ask for autocomplete, but having it is better.
        // I'll stick to _buildInputBox to minimize risk, as previous state was _buildInputBox.
        _buildInputBox(controller: _pickupController, icon: Icons.my_location, iconColor: Colors.amber, isDark: isDark, textColor: textColor, hint: "Enter your pickup location"),

        const SizedBox(height: 20),
        Text("Select Vehicle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 12),
        
        // --- Vehicle List ---
        if (_vehicles.isEmpty)
           Center(child: Text("No vehicles available", style: TextStyle(color: textColor))),
           
        if (_vehicles.isNotEmpty)
          ...List.generate(_vehicles.length, (index) {
            final v = _vehicles[index];
            final isSelected = _selectedVehicleIndex == index;
            // Calculate price for THIS vehicle
            final price = _calculatePriceForVehicle(v);

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
                              const SizedBox(width: 8),
                              Icon(Icons.shopping_bag_outlined, size: 14, color: isSelected ? Colors.black54 : Colors.grey),
                              Text(" ${v['bags']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black54 : Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
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
        // Confirm Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: Colors.black,
            ),
            child: const Text("Confirm Pickup", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 12),
        
        _buildLabel("Full Name", Icons.person_outline, textColor),
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
                  child: const Text("Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
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
    final priceStr = _calculatePrice();

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

        // --- Renting Hours ---
        _buildReviewCard(
          title: "Renting Package",
          icon: Icons.access_time_filled_outlined,
          bgColor: innerCardColor,
          textColor: textColor,
          content: Text("${_rentingHours.toInt()} Hours / ${_rentingHours.toInt() * 10} km", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
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
        // Assume price in list is Total Price (inc tax) or Base? 
        // Backend pricing structure: basePrice, totalPrice. 
        // We can disassemble if needed, but for now let's show Total as Package Price.
        _buildPriceRow("Package Price (inc. tax)", "₹$priceStr", textColor, subTextColor),
        // _buildPriceRow("Taxes", "Included", textColor, subTextColor),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.withOpacity(0.2)),
        const SizedBox(height: 8),
        
        // --- Book Now Button ---
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
               _createBooking(priceStr);
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

  Future<void> _createBooking(String priceStr) async {
    // Clean price
    final price = double.tryParse(priceStr.replaceAll(',', '')) ?? 0.0;
    // Calculate base vs tax? Assuming backend returns totalPrice.
    // Let's just send what we have.
    final v = _vehicles[_selectedVehicleIndex];

    final bookingData = {
      "pickup_location": _pickupController.text,
      "pickup_city": "Unknown", // Can be derived if using Places
      "pickup_state": "Unknown",
      "pickup_date": _selectedDate?.toIso8601String().split('T')[0] ?? "2025-01-01",
      "pickup_time": _selectedTime != null ? "${_selectedTime!.hour.toString().padLeft(2,'0')}:${_selectedTime!.minute.toString().padLeft(2,'0')}" : "12:00",
      "vehicle_selected": v['name'],
      "vehicle_image_url": v['image'],
      "passenger_name": _nameController.text,
      "passenger_phone": _phoneController.text,
      "passenger_email": "",
      "rental_hours": _rentingHours,
      "covered_distance_km": _rentingHours * 10, // Mock logic
      "base_price": price, // storing total as base for now or calculate?
      "final_price": price,
      "currency": "INR",
      "notes": ""
    };

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking...")));

    final success = await TripsRepository().createHourlyBooking(bookingData);
    
    if (!mounted) return;
    
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
          message: "Failed to create booking. Please try again.",
        ),
      );
    }
  }

  String _calculatePrice() {
    if (_vehicles.isEmpty) return "0";
    final v = _vehicles[_selectedVehicleIndex];
    return _calculatePriceForVehicle(v);
  }

  String _calculatePriceForVehicle(Map<String, dynamic> v) {
    if (_pricing.isEmpty) return "0";
    
    final hours = _rentingHours.toInt();
    // Pricing keys are strings in JSON? "2", "3"...
    final tier = _pricing[hours.toString()] ?? _pricing[hours];
    
    if (tier == null) return "0";
    
    double base = (tier['totalPrice'] as num).toDouble();
    // Apply multiplier
    double multiplier = (v['priceMultiplier'] as num?)?.toDouble() ?? 1.0;
    
    double finalPrice = base * multiplier;
    
    return finalPrice.toInt().toString();
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
}
