/// Vehicle makes and models helper class
/// This class now works with data fetched from the backend
class VehicleMakesModels {
  final Map<String, List<String>> makesAndModels;

  VehicleMakesModels(this.makesAndModels);

  /// Get all available makes
  List<String> get makes => makesAndModels.keys.toList();

  /// Get models for a specific make
  List<String> getModelsForMake(String make) {
    return makesAndModels[make] ?? [];
  }

  /// Check if a make exists
  bool isValidMake(String make) {
    return makesAndModels.containsKey(make);
  }

  /// Check if a model is valid for a make
  bool isValidModelForMake(String make, String model) {
    return makesAndModels[make]?.contains(model) ?? false;
  }
}
