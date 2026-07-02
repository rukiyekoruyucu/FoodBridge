import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/inventory_notifier.dart';
import 'package:foodbridge/providers/inventory_state.dart';
import 'package:foodbridge/models/product_item.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class ProductAddScreen extends StatelessWidget {
  const ProductAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    if (isDark) {
      content = const GlassBox(
        child: Text(
          'Product Add Form (yakında)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      );
    } else {
      content = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          'Product Add Form (yakında)',
          style: TextStyle(color: AppShell.kInk, fontWeight: FontWeight.w900),
        ),
      );
    }

    return AppShell(
      appBar: buildGlassAppBar(context: context, title: 'Ürün ekle'),
      body: Center(child: content),
    );
  }
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadInventory();
    });
  }

  void _simulateTransferToFridge(ProductItem item) {
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    const simulatedFridgeId = 'fridge_123';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Waiting fridge selection for ${item.name} to $simulatedFridgeId..',
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    inventoryNotifier
        .transferToFridge(item.itemId, simulatedFridgeId)
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Succesfully transfered ${item.name} to fridge $simulatedFridgeId',
                ),
              ),
            );
          }
        })
        .catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transfer failed: ${e.toString()}')),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<InventoryState>(inventoryProvider, (previous, current) {
      if (current.error != null && !current.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory Error: ${current.error}')),
        );
      }
    });

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: 'Envanterim',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductAddScreen(),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Product Clicked')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: inventoryState.isLoading
                ? null
                : () => ref.read(inventoryProvider.notifier).loadInventory(),
          ),
        ],
      ),
      body: _buildBody(inventoryState, isDark),
    );
  }

  Widget _card({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
  }) {
    if (isDark) {
      return GlassBox(padding: padding, child: child);
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBody(InventoryState state, bool isDark) {
    if (state.isLoading && state.inventoryItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.inventoryItems.isEmpty) {
      return Center(
        child: Text(
          'Envanterde ürün yok.',
          style: TextStyle(
            color: isDark ? Colors.white : AppShell.kInk,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      itemCount: state.inventoryItems.length,
      itemBuilder: (context, index) {
        final item = state.inventoryItems[index];

        final titleColor = isDark ? Colors.white : AppShell.kInk;
        final subColor = isDark
            ? Colors.white.withValues(alpha: 0.9)
            : AppShell.kInk.withValues(alpha: 0.75);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _card(
            isDark: isDark,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adet: ${item.quantity} • Kategori: ${item.category}',
                        style: TextStyle(
                          color: subColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => _simulateTransferToFridge(item),
                  style: !isDark
                      ? ElevatedButton.styleFrom(
                          backgroundColor: AppShell.kGreen,
                          foregroundColor: Colors.white,
                        )
                      : null,
                  child: Text(state.isLoading ? 'Loading...' : 'Taşı'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
