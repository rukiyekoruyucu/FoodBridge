import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/inventory_notifier.dart';
import 'package:foodbridge/providers/inventory_state.dart';
import 'package:foodbridge/models/product_item.dart';

//import
//import

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>{
  @override
  void initState(){
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_){
      ref.read(inventoryProvider.notifier).loadInventory();
    });
  }

  void _showFridgeSelectionModal(ProductItem item){
    final inventoryNotifier = ref.read(inventoryProvider.notifier);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Waiting fridge selection for ${item.name}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Transfer simulate',
          onPressed: () async {
            const simulatedFridgeId = 'fridge_123';

            try{
              await inventoryNotifier.transferToFridge(item.itemId, simulatedFridgeId);

              if(mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Succesfully transfered ${item.name} to your fridge'))
                );
              }
            } catch (e){
              if(mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Transfer failed: ${e.toString()}'))
                );
              }
            }
          }
        ) )
    );

  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    ref.listen<InventoryState>(inventoryProvider, (previous, current) {
      if (current.error != null && !current.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory Error: ${current.error}')),
        );
      }
    });
   
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () {
              //Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProductAddScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Product Clicked')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: inventoryState.isLoading ? null : () =>
              ref.read(inventoryProvider.notifier).loadInventory(),         
          ),
        ],
      ),

      body: _buildBody(inventoryState),
    );
  }

  Widget _buildBody(InventoryState state) {
    if (state.isLoading && state.inventoryItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } 
    if (state.inventoryItems.isEmpty) {
      return const Center(child: Text('No items in inventory.'));
    }

    return ListView.builder(
      itemCount: state.inventoryItems.length,
      itemBuilder: (context, index) {
        final item = state.inventoryItems[index];
        return ListTile(
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Quantity: ${item.quantity} - Category: ${item.category}'),
          trailing: ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () {
                    _showFridgeSelectionModal(item);
                  },
            child: Text(state.isLoading ? 'Loading...' : 'Move product'),
          ),
        );
      },
    );
  }

}