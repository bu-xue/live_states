import 'package:flutter/material.dart';
import 'package:live_states/live_states.dart';

void main() {
  runApp(const MaterialApp(
    home: ShoppingPage(),
    debugShowCheckedModeBanner: false,
  ));
}

// ==========================================
// 场景 1: 基础购物车
// ==========================================

class ShoppingVM extends LiveViewModel<ShoppingPage> with Recoverable {
  @override
  String get storageKey => 'shopping_vm_storage';

  late final searchKey = LiveData<String>('', owner, debugName: 'search_key');
  late final items = LiveData<List<String>>(
      ['Apple', 'Banana', 'Cherry', 'Date', 'Eggplant'], owner, debugName: 'all_products');
  late final cart = LiveData<Set<String>>({}, owner, debugName: 'shopping_cart');

  late final filteredItems = LiveCompute<List<String>>(owner, () {
    if (searchKey.value.isEmpty) return items.value;
    return items.value
        .where((i) => i.toLowerCase().contains(searchKey.value.toLowerCase()))
        .toList();
  }, debugName: 'filtered_list_logic');

  late final cartCount = LiveCompute<int>(owner, () => cart.value.length, debugName: 'cart_count_logic');

  void toggleCart(String item) {
    final newCart = {...cart.value};
    if (newCart.contains(item)) {
      newCart.remove(item);
    } else {
      newCart.add(item);
    }
    cart.value = newCart;
  }

  @override
  Map<String, dynamic>? storage() => {'search': searchKey.value};

  @override
  void recover(Map<String, dynamic>? storage) {
    if (storage != null) searchKey.value = storage['search'] ?? '';
  }
}

class ShoppingPage extends LiveWidget {
  const ShoppingPage({super.key});

  @override
  ShoppingVM createViewModel() => ShoppingVM();

  @override
  Widget build(BuildContext context, ShoppingVM viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveStates Example'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => viewModel.searchKey.value = v,
              controller: TextEditingController(text: viewModel.searchKey.value)
                ..selection = TextSelection.collapsed(offset: viewModel.searchKey.value.length),
            ),
          ),
          Expanded(
            child: LiveScope.free(
              debugName: 'ProductListView',
              builder: (context, _) {
                final list = viewModel.filteredItems.value;
                if (list.isEmpty) return const Center(child: Text('No items found.'));
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return ListTile(
                      title: Text(item),
                      trailing: LiveScope.free(
                        debugName: 'CartItem_$item',
                        builder: (context, _) {
                          final isInCart = viewModel.cart.value.contains(item);
                          return IconButton(
                            icon: Icon(isInCart ? Icons.remove_circle : Icons.add_circle),
                            color: isInCart ? Colors.red : Colors.green,
                            onPressed: () => viewModel.toggleCart(item),
                          );
                        }
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: LiveScope.free(
        debugName: 'CartBadgeFAB',
        builder: (context, _) => Badge(
          label: Text('${viewModel.cartCount.value}'),
          isLabelVisible: viewModel.cartCount.value > 0,
          child: FloatingActionButton(
            onPressed: () {
              final count = viewModel.cartCount.value;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(count > 0 ? 'You have $count items' : 'Cart empty')),
              );
            },
            child: const Icon(Icons.shopping_cart),
          ),
        ),
      ),
    );
  }
}

