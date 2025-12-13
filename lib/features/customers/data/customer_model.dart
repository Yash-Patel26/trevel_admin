class Customer {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final int bookingsCount;
  final int upcomingBookingsCount;
  final String status; // 'active' or 'inactive'

  Customer({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.bookingsCount,
    required this.upcomingBookingsCount,
    required this.status,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      bookingsCount: json['bookingsCount'] as int? ?? 0,
      upcomingBookingsCount: json['upcomingBookingsCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'inactive',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'bookingsCount': bookingsCount,
      'upcomingBookingsCount': upcomingBookingsCount,
      'status': status,
    };
  }
}

class CustomerStats {
  final int totalCustomers;
  final int totalBookings;
  final int upcomingBookings;
  final int cancelledBookings;

  CustomerStats({
    required this.totalCustomers,
    required this.totalBookings,
    required this.upcomingBookings,
    required this.cancelledBookings,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      totalCustomers: json['totalCustomers'] as int? ?? 0,
      totalBookings: json['totalBookings'] as int? ?? 0,
      upcomingBookings: json['upcomingBookings'] as int? ?? 0,
      cancelledBookings: json['cancelledBookings'] as int? ?? 0,
    );
  }
}
