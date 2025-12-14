import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pricing_config.dart';
import '../revenue_provider.dart';

class HourlyRentalPricingForm extends ConsumerStatefulWidget {
  final PricingConfig config;

  const HourlyRentalPricingForm({super.key, required this.config});

  @override
  ConsumerState<HourlyRentalPricingForm> createState() => _HourlyRentalPricingFormState();
}

class _HourlyRentalPricingFormState extends ConsumerState<HourlyRentalPricingForm> {
  final _formKey = GlobalKey<FormState>();
  late List<Map<String, dynamic>> _packageControllers; 
  // Structure: { 'hour': int, 'baseCtrl': Controller, 'totalCtrl': Controller }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final packagesMap = Map<String, dynamic>.from(widget.config.config['packages']);
    
    // Sort keys (hours)
    final sortedKeys = packagesMap.keys.map((k) => int.parse(k)).toList()..sort();
    
    _packageControllers = sortedKeys.map((hour) {
      final pkg = packagesMap[hour.toString()];
      return {
        'hour': hour,
        'baseCtrl': TextEditingController(text: pkg['basePrice'].toString()),
        'totalCtrl': TextEditingController(text: pkg['totalPrice'].toString()),
      };
    }).toList();
  }

  @override
  void dispose() {
    for (var item in _packageControllers) {
      (item['baseCtrl'] as TextEditingController).dispose();
      (item['totalCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final newPackages = {};
      
      for (var item in _packageControllers) {
        newPackages[item['hour'].toString()] = {
          'basePrice': double.parse((item['baseCtrl'] as TextEditingController).text),
          'totalPrice': double.parse((item['totalCtrl'] as TextEditingController).text),
        };
      }

      final newConfig = Map<String, dynamic>.from(widget.config.config);
      newConfig['packages'] = newPackages;

      await ref.read(revenueControllerProvider.notifier).updateConfig(
        widget.config.serviceType, 
        newConfig
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental Packages Updated Successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hourly Packages', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ..._packageControllers.map((item) {
            final hour = item['hour'];
            final baseCtrl = item['baseCtrl'] as TextEditingController;
            final totalCtrl = item['totalCtrl'] as TextEditingController;

            return Card(
              child: ListTile(
                title: Text('$hour Hours Package'),
                subtitle: Row(
                  children: [
                    Expanded(child: _buildField(baseCtrl, 'Base Price')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField(totalCtrl, 'Total Price')),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
