import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pricing_config.dart';
import '../revenue_provider.dart';

class MiniTravelPricingForm extends ConsumerStatefulWidget {
  final PricingConfig config;

  const MiniTravelPricingForm({super.key, required this.config});

  @override
  ConsumerState<MiniTravelPricingForm> createState() => _MiniTravelPricingFormState();
}

class _MiniTravelPricingFormState extends ConsumerState<MiniTravelPricingForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late List<Map<String, TextEditingController>> _tierControllers;
  late TextEditingController _peakPerKmController;
  late TextEditingController _peakBaseController;
  late TextEditingController _nonPeakPerKmController;
  late TextEditingController _nonPeakBaseController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    final tiers = (widget.config.config['tiers'] as List);
    final beyond30 = widget.config.config['beyond30Km'];
    
    _tierControllers = tiers.map((tier) => {
      'minKm': TextEditingController(text: tier['minKm'].toString()),
      'maxKm': TextEditingController(text: tier['maxKm'].toString()),
      'peakBase': TextEditingController(text: tier['peakBasePrice'].toString()),
      'nonPeakBase': TextEditingController(text: tier['nonPeakBasePrice'].toString()),
    }).toList();
    
    _peakPerKmController = TextEditingController(text: beyond30['peak']['perKmRate'].toString());
    _peakBaseController = TextEditingController(text: beyond30['peak']['baseCharge'].toString());
    _nonPeakPerKmController = TextEditingController(text: beyond30['nonPeak']['perKmRate'].toString());
    _nonPeakBaseController = TextEditingController(text: beyond30['nonPeak']['baseCharge'].toString());
  }

  @override
  void dispose() {
    for (var map in _tierControllers) {
      map.values.forEach((c) => c.dispose());
    }
    _peakPerKmController.dispose();
    _peakBaseController.dispose();
    _nonPeakPerKmController.dispose();
    _nonPeakBaseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final tiers = _tierControllers.map((map) => {
        'minKm': double.parse(map['minKm']!.text),
        'maxKm': double.parse(map['maxKm']!.text),
        'peakBasePrice': double.parse(map['peakBase']!.text),
        'nonPeakBasePrice': double.parse(map['nonPeakBase']!.text),
      }).toList();

      final beyond30 = {
        'peak': {
          'perKmRate': double.parse(_peakPerKmController.text),
          'baseCharge': double.parse(_peakBaseController.text),
        },
        'nonPeak': {
          'perKmRate': double.parse(_nonPeakPerKmController.text),
          'baseCharge': double.parse(_nonPeakBaseController.text),
        }
      };
      
      final newConfig = Map<String, dynamic>.from(widget.config.config);
      newConfig['tiers'] = tiers;
      newConfig['beyond30Km'] = beyond30;

      await ref.read(revenueControllerProvider.notifier).updateConfig(
        widget.config.serviceType, 
        newConfig
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing Updated Successfully')),
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
          Text('Distance Tiers (< 30km)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ..._tierControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controllers = entry.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tier ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(child: _buildField(controllers['minKm']!, 'Min Km')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildField(controllers['maxKm']!, 'Max Km')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildField(controllers['peakBase']!, 'Peak Price')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildField(controllers['nonPeakBase']!, 'Non-Peak Price')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text('Beyond 30km Charges', style: Theme.of(context).textTheme.titleLarge),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   const Text('Peak Hours'),
                   Row(
                    children: [
                      Expanded(child: _buildField(_peakPerKmController, 'Per Km Rate')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildField(_peakBaseController, 'Base Charge')),
                    ],
                  ),
                   const SizedBox(height: 10),
                   const Text('Non-Peak Hours'),
                   Row(
                    children: [
                      Expanded(child: _buildField(_nonPeakPerKmController, 'Per Km Rate')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildField(_nonPeakBaseController, 'Base Charge')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Changes'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
