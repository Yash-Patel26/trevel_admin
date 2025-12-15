import 'dart:async';
import 'driver_document.dart';
import 'driver_model.dart';

/// Mock storage service for drivers (bypasses backend)
class MockDriverStorage {
  static final MockDriverStorage _instance = MockDriverStorage._internal();
  factory MockDriverStorage() => _instance;
  MockDriverStorage._internal();

  final List<Driver> _drivers = [];
  int _nextId = 1;
  final _controller = StreamController<List<Driver>>.broadcast();

  Stream<List<Driver>> get driversStream => _controller.stream;

  /// Initialize with some sample data
  void initialize() {
    if (_drivers.isEmpty) {
      _drivers.addAll([
        Driver(
          id: (_nextId++).toString(),
          fullName: 'John Doe',
          email: 'john.doe@example.com',
          mobile: '+1234567890',
          licenseNumber: 'DL-12345',
          status: DriverStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          backgroundCheckStatus: BackgroundCheckStatus.passed,
          backgroundCheckDate:
              DateTime.now().subtract(const Duration(days: 40)),
          trainingCompleted: true,
          assignedVehicleNumber: 'VH-001',
        ),
        Driver(
          id: (_nextId++).toString(),
          fullName: 'Jane Smith',
          email: 'jane.smith@example.com',
          mobile: '+1234567891',
          licenseNumber: 'DL-12346',
          status: DriverStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          backgroundCheckStatus: BackgroundCheckStatus.passed,
          backgroundCheckDate:
              DateTime.now().subtract(const Duration(days: 15)),
          trainingCompleted: true,
        ),
        Driver(
          id: (_nextId++).toString(),
          fullName: 'Bob Johnson',
          email: 'bob.johnson@example.com',
          mobile: '+1234567892',
          licenseNumber: 'DL-12347',
          status: DriverStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          backgroundCheckStatus: BackgroundCheckStatus.inProgress,
          backgroundCheckDate: DateTime.now().subtract(const Duration(days: 3)),
          trainingCompleted: false,
        ),
      ]);
      _notifyListeners();
    }
  }

  Future<List<Driver>> getAllDrivers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_drivers);
  }

  Future<Driver?> getDriverById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _drivers.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Driver> createDriver({
    required String fullName,
    required String email,
    required String mobile,
    String? licenseNumber,
    String? notes,
    List<DriverDocument> documents = const [],
    ContactPreferences? contactPreferences,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final driver = Driver(
      id: (_nextId++).toString(),
      fullName: fullName,
      email: email,
      mobile: mobile,
      licenseNumber: licenseNumber,
      status: DriverStatus.pending,
      createdAt: DateTime.now(),
      notes: notes,
      documents: documents,
      contactPreferences: contactPreferences ?? ContactPreferences(),
    );

    _drivers.add(driver);
    _notifyListeners();
    return driver;
  }

  Future<Driver> updateDriver(Driver driver) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _drivers.indexWhere((d) => d.id == driver.id);
    if (index != -1) {
      _drivers[index] = driver;
      _notifyListeners();
    }
    return driver;
  }

  Future<bool> deleteDriver(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _drivers.indexWhere((d) => d.id == id);
    if (index != -1) {
      _drivers.removeAt(index);
      _notifyListeners();
      return true;
    }
    return false;
  }

  void _notifyListeners() {
    _controller.add(List.unmodifiable(_drivers));
  }

  void dispose() {
    _controller.close();
  }
}
