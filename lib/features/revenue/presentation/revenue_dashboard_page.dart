import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'revenue_provider.dart';
import 'widgets/mini_travel_pricing_form.dart';
import 'widgets/hourly_rental_pricing_form.dart';
import 'widgets/airport_pricing_form.dart';

class RevenueDashboardPage extends ConsumerStatefulWidget {
  const RevenueDashboardPage({super.key});

  @override
  ConsumerState<RevenueDashboardPage> createState() => _RevenueDashboardPageState();
}

class _RevenueDashboardPageState extends ConsumerState<RevenueDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configsAsync = ref.watch(pricingConfigsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Revenue Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Mini Trip'),
            Tab(text: 'Hourly Rental'),
            Tab(text: 'Airport Transfer'),
          ],
        ),
      ),
      body: configsAsync.when(
        data: (configs) {
          // Find config for each type or pass null (widgets should handle defaults/nulls)
          final miniTripConfig = configs.firstWhere(
            (c) => c.serviceType == 'mini-travel', 
            orElse: () => throw Exception('Mini Travel config missing')
          );
          
          final hourlyConfig = configs.firstWhere(
            (c) => c.serviceType == 'hourly-rental',
            orElse: () => throw Exception('Hourly Rental config missing')
          );
          
          final airportDropConfig = configs.firstWhere(
            (c) => c.serviceType == 'airport-drop',
            orElse: () => throw Exception('Airport Drop config missing')
          );
           final airportPickupConfig = configs.firstWhere(
            (c) => c.serviceType == 'airport-pickup',
            orElse: () => throw Exception('Airport Pickup config missing')
          );

          return TabBarView(
            controller: _tabController,
            children: [
              MiniTravelPricingForm(config: miniTripConfig),
              HourlyRentalPricingForm(config: hourlyConfig),
              AirportPricingForm(dropConfig: airportDropConfig, pickupConfig: airportPickupConfig),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
