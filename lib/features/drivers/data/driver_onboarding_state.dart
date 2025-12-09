import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'driver_document.dart';

/// State for driver onboarding flow (shared across multiple steps)
class DriverOnboardingState {
  // Step 1: Basic Information
  final String? fullName;
  final String? email;
  final String? mobile;
  final String? bloodGroup;
  final DateTime? dateOfBirth;
  final String? profileImageUrl;
  final String?
      shiftTiming; // e.g., 'morning', 'afternoon', 'evening', 'night', 'flexible'

  // Step 2: Documents
  final List<DriverDocument> documents;

  // Step 3: Contact Preferences & Addresses
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final String? preferredContactMethod;

  // Addresses
  final String? currentAddress;
  final String? permanentAddress;

  // Reference Contacts
  final String? referenceContact1Name;
  final String? referenceContact1Mobile;
  final String? referenceContact1Relation;
  final String? referenceContact2Name;
  final String? referenceContact2Mobile;
  final String? referenceContact2Relation;

  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? emergencyContactRelation;

  // Step 4: Verification approvals
  final Set<String> approvedSections; // Track which sections are approved

  // Step 5: Vehicle Allocation
  final int? assignedVehicleId;

  // Step 6-7: Information only (no data needed)

  // Notes
  final String? notes;

  DriverOnboardingState({
    this.fullName,
    this.email,
    this.mobile,
    this.bloodGroup,
    this.dateOfBirth,
    this.profileImageUrl,
    this.shiftTiming,
    this.documents = const [],
    this.emailNotifications = true,
    this.smsNotifications = true,
    this.pushNotifications = true,
    this.preferredContactMethod,
    this.currentAddress,
    this.permanentAddress,
    this.referenceContact1Name,
    this.referenceContact1Mobile,
    this.referenceContact1Relation,
    this.referenceContact2Name,
    this.referenceContact2Mobile,
    this.referenceContact2Relation,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.emergencyContactRelation,
    Set<String>? approvedSections,
    this.assignedVehicleId,
    this.notes,
  }) : approvedSections = approvedSections ?? const {};

  DriverOnboardingState copyWith({
    String? fullName,
    String? email,
    String? mobile,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    String? shiftTiming,
    List<DriverDocument>? documents,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
    String? preferredContactMethod,
    String? currentAddress,
    String? permanentAddress,
    String? referenceContact1Name,
    String? referenceContact1Mobile,
    String? referenceContact1Relation,
    String? referenceContact2Name,
    String? referenceContact2Mobile,
    String? referenceContact2Relation,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? emergencyContactRelation,
    Set<String>? approvedSections,
    int? assignedVehicleId,
    String? notes,
  }) {
    return DriverOnboardingState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      shiftTiming: shiftTiming ?? this.shiftTiming,
      documents: documents ?? this.documents,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      preferredContactMethod:
          preferredContactMethod ?? this.preferredContactMethod,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      referenceContact1Name:
          referenceContact1Name ?? this.referenceContact1Name,
      referenceContact1Mobile:
          referenceContact1Mobile ?? this.referenceContact1Mobile,
      referenceContact1Relation:
          referenceContact1Relation ?? this.referenceContact1Relation,
      referenceContact2Name:
          referenceContact2Name ?? this.referenceContact2Name,
      referenceContact2Mobile:
          referenceContact2Mobile ?? this.referenceContact2Mobile,
      referenceContact2Relation:
          referenceContact2Relation ?? this.referenceContact2Relation,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber:
          emergencyContactNumber ?? this.emergencyContactNumber,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      approvedSections: approvedSections ?? this.approvedSections,
      assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
      notes: notes ?? this.notes,
    );
  }

  bool get isStep1Complete =>
      fullName != null &&
      fullName!.isNotEmpty &&
      email != null &&
      email!.isNotEmpty &&
      mobile != null &&
      mobile!.isNotEmpty;
}

/// Provider to hold driver onboarding state across multiple screens
final driverOnboardingStateProvider =
    StateNotifierProvider<DriverOnboardingNotifier, DriverOnboardingState>(
        (ref) {
  return DriverOnboardingNotifier();
});

class DriverOnboardingNotifier extends StateNotifier<DriverOnboardingState> {
  DriverOnboardingNotifier() : super(DriverOnboardingState());

  void updateBasicInfo({
    String? fullName,
    String? email,
    String? mobile,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    String? shiftTiming,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      mobile: mobile,
      bloodGroup: bloodGroup,
      dateOfBirth: dateOfBirth,
      profileImageUrl: profileImageUrl,
      shiftTiming: shiftTiming,
    );
  }

  void updateDocuments(List<DriverDocument> documents) {
    state = state.copyWith(documents: documents);
  }

  void updateContactPreferences({
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
    String? preferredContactMethod,
    String? currentAddress,
    String? permanentAddress,
    String? referenceContact1Name,
    String? referenceContact1Mobile,
    String? referenceContact1Relation,
    String? referenceContact2Name,
    String? referenceContact2Mobile,
    String? referenceContact2Relation,
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? emergencyContactRelation,
  }) {
    state = state.copyWith(
      emailNotifications: emailNotifications,
      smsNotifications: smsNotifications,
      pushNotifications: pushNotifications,
      preferredContactMethod: preferredContactMethod,
      currentAddress: currentAddress,
      permanentAddress: permanentAddress,
      referenceContact1Name: referenceContact1Name,
      referenceContact1Mobile: referenceContact1Mobile,
      referenceContact1Relation: referenceContact1Relation,
      referenceContact2Name: referenceContact2Name,
      referenceContact2Mobile: referenceContact2Mobile,
      referenceContact2Relation: referenceContact2Relation,
      emergencyContactName: emergencyContactName,
      emergencyContactNumber: emergencyContactNumber,
      emergencyContactRelation: emergencyContactRelation,
    );
  }

  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void updateAssignedVehicle(int? vehicleId) {
    state = state.copyWith(assignedVehicleId: vehicleId);
  }

  void approveSection(String sectionKey) {
    final updatedSections = Set<String>.from(state.approvedSections)
      ..add(sectionKey);
    state = state.copyWith(approvedSections: updatedSections);
  }

  void disapproveSection(String sectionKey) {
    final updatedSections = Set<String>.from(state.approvedSections)
      ..remove(sectionKey);
    state = state.copyWith(approvedSections: updatedSections);
  }

  void reset() {
    state = DriverOnboardingState();
  }
}
