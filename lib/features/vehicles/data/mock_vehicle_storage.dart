import 'dart:async';
import 'vehicle_model.dart';

/// Mock storage service for vehicles (bypasses backend)
class MockVehicleStorage {
  static final MockVehicleStorage _instance = MockVehicleStorage._internal();
  factory MockVehicleStorage() => _instance;
  MockVehicleStorage._internal();

  final List<Vehicle> _vehicles = [];
  int _nextId = 1;
  final _controller = StreamController<List<Vehicle>>.broadcast();

  Stream<List<Vehicle>> get vehiclesStream => _controller.stream;

  /// Initialize with some sample data
  void initialize() {
    if (_vehicles.isEmpty) {
      _vehicles.addAll([
        Vehicle(
          id: _nextId++,
          vehicleNumber: 'VH-001',
          make: 'Toyota',
          model: 'Camry',
          year: 2023,
          color: 'Black', // Constant color
          licensePlate: 'ABC-1234',
          status: VehicleStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Vehicle(
          id: _nextId++,
          vehicleNumber: 'VH-002',
          make: 'Honda',
          model: 'CR-V',
          year: 2022,
          color: 'Black', // Constant color
          licensePlate: 'XYZ-5678',
          status: VehicleStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Vehicle(
          id: _nextId++,
          vehicleNumber: 'VH-003',
          make: 'Ford',
          model: 'Transit',
          year: 2021,
          color: 'Black', // Constant color
          licensePlate: 'DEF-9012',
          status: VehicleStatus.maintenance,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ]);
      _notifyListeners();
    }
  }

  Future<List<Vehicle>> getAllVehicles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_vehicles);
  }

  Future<Vehicle?> getVehicleById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Vehicle> createVehicle({
    required String vehicleNumber,
    required String make,
    required String model,
    required int year,
    required String licensePlate,
    String? notes,
    String? insuranceDetails,
    String? insurancePolicyNumber,
    DateTime? insuranceExpiryDate,
    String? liveLocationAccessKey,
    String? dashcamAccessKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final vehicle = Vehicle(
      id: _nextId++,
      vehicleNumber: vehicleNumber,
      make: make,
      model: model,
      year: year,
      color: 'Black', // Constant color - always Black
      licensePlate: licensePlate,
      status: VehicleStatus.pending,
      createdAt: DateTime.now(),
      notes: notes,
      insuranceDetails: insuranceDetails,
      insurancePolicyNumber: insurancePolicyNumber,
      insuranceExpiryDate: insuranceExpiryDate,
      liveLocationAccessKey: liveLocationAccessKey,
      dashcamAccessKey: dashcamAccessKey,
    );

    _vehicles.add(vehicle);
    _notifyListeners();
    return vehicle;
  }

  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
      _notifyListeners();
    }
    return vehicle;
  }

  Future<bool> deleteVehicle(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index != -1) {
      _vehicles.removeAt(index);
      _notifyListeners();
      return true;
    }
    return false;
  }

  void _notifyListeners() {
    _controller.add(List.unmodifiable(_vehicles));
  }

  void dispose() {
    _controller.close();
  }
}
