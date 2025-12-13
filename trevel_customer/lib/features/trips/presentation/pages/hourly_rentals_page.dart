import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_bottom_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import 'my_bookings_page.dart';

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
  final TextEditingController _dateController = TextEditingController(text: "Dec 03,2025");
  final TextEditingController _timeController = TextEditingController(text: "4:00 PM");
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final List<Map<String, dynamic>> _vehicles = [
    {
      "name": "MG Windsor",
      "seats": 4,
      "bags": 3,
      "price": "₹799", // Base price
      "image": "assets/images/taxi.jpeg", 
    },
    {
      "name": "BYD emax",
      "seats": 7,
      "bags": 3,
      "price": "₹999",
      "image": "assets/images/taxi.jpeg",
    },
    {
      "name": "Kia cerens",
      "seats": 7,
      "bags": 4,
      "price": "₹999",
      "image": "assets/images/taxi.jpeg",
    },
    {
      "name": "BMW iX1",
      "seats": 4,
      "bags": 4,
      "price": "₹1,499",
      "image": "assets/images/taxi.jpeg",
    },
  ];

  @override
  void initState() {
    super.initState();
    _fillUserData();
  }

  void _fillUserData() {
    // Determine if we should autofill based on _travelerType? 
    // Usually if defaults to Myself (0), we fill.
    if (_travelerType == 0) {
      _nameController.text = "Yash Patel";
      _phoneController.text = "9876543210";
    }
  }

  void _clearUserData() {
    _nameController.clear();
    _phoneController.clear();
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
            Expanded(child: _buildInputBox(controller: _dateController, isDark: isDark, textColor: textColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputBox(controller: _timeController, icon: Icons.access_time, isDark: isDark, textColor: textColor)),
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
        Text(" ₹ ${_calculatePrice()}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),


        const SizedBox(height: 20),
        _buildLabel("Pickup Location", Icons.location_on_outlined, textColor),
        const SizedBox(height: 8),
        _buildInputBox(controller: _pickupController, icon: Icons.my_location, iconColor: Colors.green, isDark: isDark, textColor: textColor),

        const SizedBox(height: 20),
        Text("Select Vehicle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 12),
        
        // --- Vehicle List ---
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
                            const SizedBox(width: 8),
                            Icon(Icons.shopping_bag_outlined, size: 14, color: isSelected ? Colors.black54 : Colors.grey),
                            Text(" ${v['bags']}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.black54 : Colors.grey)),
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

        // --- Renting Hours (Replacing Destination) ---
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
        _buildPriceRow("Package Price", "₹899", textColor, subTextColor),
        const SizedBox(height: 8),
        _buildPriceRow("Taxes", "₹50", textColor, subTextColor),
        const SizedBox(height: 8),
        Divider(color: Colors.grey.withOpacity(0.2)),
        const SizedBox(height: 8),
        
        // --- Book Now Button ---
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
               // Show Booking Confirmation
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   backgroundColor: Theme.of(context).cardColor,
                   title: Text("Booking Confirmed", style: TextStyle(color: textColor)),
                   content: Text("Your Hourly Rental has been booked successfully!", style: TextStyle(color: textColor)),
                   actions: [
                     TextButton(
                       onPressed: () {
                         Navigator.pop(context); // Close dialog
                         Navigator.pop(context); // Go back to Home
                       },
                       child: const Text("OK", style: TextStyle(color: Colors.amber)),
                     ),
                   ],
                 ),
               );
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

  String _calculatePrice() {
     // Placeholder
    return "999"; 
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

  Widget _buildInputBox({String? hint, TextEditingController? controller, IconData? icon, Color? iconColor, required bool isDark, required Color textColor}) {
    Color innerCardColor = isDark ? Colors.grey[850]! : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: innerCardColor,
        boxShadow: [
           // BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 2, offset: Offset(0,1))
        ]
      ),
      child: TextField(
        controller: controller,
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
}
