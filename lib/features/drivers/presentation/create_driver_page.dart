import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/driver_onboarding_state.dart';

/// Entry point for driver onboarding - redirects to step 1
class CreateDriverPage extends ConsumerWidget {
  const CreateDriverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset onboarding state when starting new onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverOnboardingStateProvider.notifier).reset();
      if (context.mounted) {
        context.go('/drivers/onboard/step1');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
