import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/fridges_notifier.dart';
import 'package:foodbridge/providers/fridges_state.dart';
import 'package:foodbridge/screens/fridge_detail_screen.dart';

class FridgeListScreen extends ConsumerWidget {
  const FridgeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fridgesState = ref.watch(fridgesProvider);

    if(fridgesState.fridges.isEmpty && !fridgesState.isLoading && fridgesState.error == null) {
      // Load fridges when the screen is first built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(fridgesProvider.notifier).loadFridgesNearMe();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Fridges'),
      ),
      body: _buildBody(fridgesState, ref),      
    );
  }

  Widget _buildBody(FridgesState state, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                ref.read(fridgesProvider.notifier).loadFridgesNearMe(),
              child: const Text('Try locating me again'),
            ),
          ],
            ),
        );
    }
      if (state.fridges.isEmpty) {
      return const Center(child: Text('No fridges found nearby.'));
  }

  return ListView.builder(
      itemCount: state.fridges.length,
      itemBuilder: (context, index) {
        final fridge = state.fridges[index];
        return ListTile(
          title: Text(fridge.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            'Distance: ${fridge.distance.toStringAsFixed(1) } km -'
            'Product: ${fridge.itemCount} items'
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey,),

          onTap: () {
            // Handle fridge tap, e.g., navigate to fridge details
            Navigator.of( context).push(
              MaterialPageRoute(
                builder: (context) => FridgeDetailScreen(fridgeId: fridge.fridgeId, fridgeName: fridge.name),
              ),
            );
          },
        );
      },
    );
  }
}