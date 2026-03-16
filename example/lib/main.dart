import 'package:flutter/material.dart';
import 'package:live_states/live_states.dart';

void main() {
  runApp(const MaterialApp(
    home: ShoppingPage(),
    debugShowCheckedModeBanner: false,
  ));
}

/// 1. ViewModel: 业务逻辑中心
/// 混入 Recoverable 让搜索词在页面销毁重建后依然存在
class ShoppingVM extends LiveViewModel<ShoppingPage> with Recoverable {
  @override
  String get storageKey => 'shopping_vm_storage';

  // 响应式状态
  late final searchKey = LiveData<String>('', owner, debugName: 'search');
  late final items = LiveData<List<String>>(
      ['Apple', 'Banana', 'Cherry', 'Date', 'Eggplant'], owner);
  late final cart = LiveData<Set<String>>({}, owner, debugName: 'cart');

  // 2. 差异化卖点：LiveCompute (自动追踪依赖 + 结果缓存)
  // 只有当 searchKey 或 items 改变，且过滤后的结果集变动时，监听者才会刷新
  late final filteredItems = LiveCompute<List<String>>(owner, () {
    debugPrint('⚡ Re-computing filtered list...');
    if (searchKey.value.isEmpty) return items.value;
    return items.value
        .where((i) => i.toLowerCase().contains(searchKey.value.toLowerCase()))
        .toList();
  });

  // 计算属性：购物车总数
  late final cartCount = LiveCompute<int>(owner, () => cart.value.length);

  // Action
  void toggleCart(String item) {
    final newCart = {...cart.value};
    if (newCart.contains(item)) {
      newCart.remove(item);
    } else {
      newCart.add(item);
    }
    cart.value = newCart;
  }

  // 状态恢复逻辑
  @override
  Map<String, dynamic>? storage() => {'search': searchKey.value};

  @override
  void recover(Map<String, dynamic>? storage) {
    if (storage != null) searchKey.value = storage['search'] ?? '';
  }
}

/// 3. View: 极简的声明式 UI
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
            // 局部刷新范围：仅列表部分
            child: LiveScope.free(
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
      floatingActionButton: RepaintBoundary(
        child: LiveScope.free(
          child: const Icon(Icons.shopping_cart),
          builder: (context, child) => Badge(
            label: Text('${viewModel.cartCount.value}'),
            isLabelVisible: viewModel.cartCount.value > 0,
            child: IconButton(
              onPressed: () {
                final count = viewModel.cartCount.value;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(count > 0
                          ? 'You have $count items in cart'
                          : 'Cart is empty')),
                );
              },
              icon: child!,
            ),
          ),
        ),
      ),
    );
  }
}
