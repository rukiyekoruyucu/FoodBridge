import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/fridge_products_notifier.dart';
import 'package:foodbridge/providers/fridge_products_state.dart';
import 'package:foodbridge/providers/donations_notifier.dart';

class FridgeDetailScreen extends ConsumerWidget {
  final String fridgeId;
  final String fridgeName;

  const FridgeDetailScreen({super.key, required this.fridgeId, required this.fridgeName});
  void _requestItem(WidgetRef ref, String itemId) async{
    final donationNotifier = ref.read(donationsProvider.notifier);

    try {
      await donationNotifier.requestItem(itemId);

      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(content: Text('Item requested successfully! Wait for donor confirmation.')),
        );
      }
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(content: Text('Failed to request item: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final state = ref.watch(fridgeProductsProvider(fridgeId));

    final isRequesting = ref.watch(donationsProvider.select((s)=> s.isLoading));

    return Scaffold(
      appBar: AppBar(title: Text('Fridge Details'),),
      body: _buildBody(state, ref, isRequesting),
      );
  }

  Widget _buildBody(FridgeProductsState state, WidgetRef ref, bool isRequesting){
    if (state.isLoading){
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null){
      return Center(child: Text('There was a problem while loading the products: ${state.error}'));
    }
    if (state.products.isEmpty){
      return const Center(child: Text('No products available in this fridge.'));
    }

    return ListView.builder(
      itemCount: state.products.length,
      itemBuilder: (context, index){
        final product = state.products[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text('Quantity: ${product.quantity}' ' Expiry: ${product.expiryDate}'),
          trailing: isRequesting 
            ? const CircularProgressIndicator() 
            : ElevatedButton(
                onPressed: () => _requestItem(ref, product.itemId), 
                child: const Text('Request')
              ),
        );
      },
    );
  }    
  }
