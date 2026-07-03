import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/service_order.dart';
import '../repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

const _uuid = Uuid();

class OrderState {
  const OrderState({
    this.orders = const [],
    this.activeOrderId,
    this.activeItemIndex = 0,
  });

  final List<ServiceOrder> orders;
  final String? activeOrderId;
  final int activeItemIndex;

  ServiceOrder? get activeOrder {
    if (activeOrderId == null) return null;
    for (final o in orders) {
      if (o.id == activeOrderId) return o;
    }
    return null;
  }

  OrderState copyWith({
    List<ServiceOrder>? orders,
    String? activeOrderId,
    int? activeItemIndex,
    bool clearActiveOrder = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      activeOrderId:
          clearActiveOrder ? null : (activeOrderId ?? this.activeOrderId),
      activeItemIndex: activeItemIndex ?? this.activeItemIndex,
    );
  }
}

class OrderNotifier extends Notifier<OrderState> {
  late OrderRepository _repo;

  @override
  OrderState build() {
    _repo = ref.read(orderRepositoryProvider);
    _load();
    return const OrderState();
  }

  Future<void> _load() async {
    await _repo.init();
    if (!ref.mounted) return;

    final orders = _repo.listOrders();
    final selection = _repo.readActiveSelection();

    String? activeOrderId = selection.orderId;
    if (activeOrderId != null && !orders.any((o) => o.id == activeOrderId)) {
      activeOrderId = null;
    }

    var activeItemIndex = selection.itemIndex;
    if (activeOrderId != null) {
      final order = orders.firstWhere((o) => o.id == activeOrderId);
      if (order.items.isEmpty) {
        activeItemIndex = 0;
      } else {
        activeItemIndex = activeItemIndex.clamp(0, order.items.length - 1);
      }
    } else {
      activeItemIndex = 0;
    }

    if (!ref.mounted) return;

    state = OrderState(
      orders: orders,
      activeOrderId: activeOrderId,
      activeItemIndex: activeItemIndex,
    );
  }

  void _persistActiveSelection() {
    _repo.saveActiveSelection(
      orderId: state.activeOrderId,
      itemIndex: state.activeItemIndex,
    );
  }

  Future<void> createOrder(String name) async {
    await _repo.init();
    final order = ServiceOrder(
      id: _uuid.v4(),
      name: name,
      items: [],
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _repo.saveOrder(order);
    state = state.copyWith(
      orders: [...state.orders, order],
      activeOrderId: order.id,
      activeItemIndex: 0,
    );
    _persistActiveSelection();
  }

  Future<void> deleteOrder(String id) async {
    await _repo.deleteOrder(id);
    final orders = state.orders.where((o) => o.id != id).toList();
    state = OrderState(
      orders: orders,
      activeOrderId: state.activeOrderId == id ? null : state.activeOrderId,
      activeItemIndex: 0,
    );
    _persistActiveSelection();
  }

  void setActiveOrder(String? id) {
    state = state.copyWith(activeOrderId: id, activeItemIndex: 0);
    _persistActiveSelection();
  }

  void setActiveItemIndex(int index) {
    state = state.copyWith(activeItemIndex: index);
    _persistActiveSelection();
  }

  Future<void> addItem(String filePath, String title) async {
    final order = state.activeOrder;
    if (order == null) return;

    final updated = order.copyWith(
      items: [
        ...order.items,
        ServiceOrderItem(filePath: filePath, title: title),
      ],
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _repo.saveOrder(updated);
    _replaceOrder(updated);
  }

  Future<void> removeItem(int index) async {
    final order = state.activeOrder;
    if (order == null || index < 0 || index >= order.items.length) return;

    final items = [...order.items]..removeAt(index);
    final updated = order.copyWith(
      items: items,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _repo.saveOrder(updated);
    final newIndex = state.activeItemIndex.clamp(0, items.length - 1);
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == updated.id ? updated : o)
          .toList(),
      activeItemIndex: items.isEmpty ? 0 : newIndex,
    );
    _persistActiveSelection();
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    final order = state.activeOrder;
    if (order == null) return;

    final items = [...order.items];
    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex >= items.length) {
      return;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final updated = order.copyWith(
      items: items,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _repo.saveOrder(updated);
    _replaceOrder(updated);
  }

  void _replaceOrder(ServiceOrder updated) {
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == updated.id ? updated : o)
          .toList(),
    );
  }
}

final orderProvider = NotifierProvider<OrderNotifier, OrderState>(
  OrderNotifier.new,
);
