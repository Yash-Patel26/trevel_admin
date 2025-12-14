import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pricing_config.dart';
import '../revenue_provider.dart';

class AirportPricingForm extends ConsumerStatefulWidget {
  final PricingConfig dropConfig;
  final PricingConfig pickupConfig;

  const AirportPricingForm({
    super.key, 
    required this.dropConfig, 
    required this.pickupConfig
  });

  @override
  ConsumerState<AirportPricingForm> createState() => _AirportPricingFormState();
}

class _AirportPricingFormState extends ConsumerState<AirportPricingForm> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _dropBaseCtrl;
  late TextEditingController _dropTotalCtrl;
  
  late TextEditingController _pickupBaseCtrl;
  late TextEditingController _pickupTotalCtrl;

  @override
  void initState() {
    super.initState();
    final dropPrice = widget.dropConfig.config['pricing'];
    final pickupPrice = widget.pickupConfig.config['pricing'];

    _dropBaseCtrl = TextEditingController(text: dropPrice['basePrice'].toString());
    _dropTotalCtrl = TextEditingController(text: dropPrice['totalPrice'].toString());
    
    _pickupBaseCtrl = TextEditingController(text: pickupPrice['basePrice'].toString());
    _pickupTotalCtrl = TextEditingController(text: pickupPrice['totalPrice'].toString());
  }
  
  @override
  void dispose() {
    _dropBaseCtrl.dispose();
    _dropTotalCtrl.dispose();
    _pickupBaseCtrl.dispose();
    _pickupTotalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
       // Update Drop Config
      final newDropConfig = Map<String, dynamic>.from(widget.dropConfig.config);
      newDropConfig['pricing'] = {
        'basePrice': double.parse(_dropBaseCtrl.text),
        'totalPrice': double.parse(_dropTotalCtrl.text),
      };
      
      // Update Pickup Config
      final newPickupConfig = Map<String, dynamic>.from(widget.pickupConfig.config);
      newPickupConfig['pricing'] = {
        'basePrice': double.parse(_pickupBaseCtrl.text),
        'totalPrice': double.parse(_pickupTotalCtrl.text),
      };

      try {
        await Future.wait([
          ref.read(revenueControllerProvider.notifier).updateConfig(widget.dropConfig.serviceType, newDropConfig),
          ref.read(revenueControllerProvider.notifier).updateConfig(widget.pickupConfig.serviceType, newPickupConfig),
        ]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Airport Pricing Updated Successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating: $e')),
          );
        }
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
          Text('Airport Transfers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          _buildCard('Airport Drop', _dropBaseCtrl, _dropTotalCtrl),
          const SizedBox(height: 16),
          _buildCard('Airport Pickup', _pickupBaseCtrl, _pickupTotalCtrl),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, TextEditingController baseCtrl, TextEditingController totalCtrl) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField(baseCtrl, 'Base Price')),
                const SizedBox(width: 10),
                Expanded(child: _buildField(totalCtrl, 'Total Price')),
              ],
            )
          ],
        ),
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
