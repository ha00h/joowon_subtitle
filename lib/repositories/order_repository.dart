import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/service_order.dart';

class ActiveOrderSelection {
  const ActiveOrderSelection({this.orderId, this.itemIndex = 0});

  final String? orderId;
  final int itemIndex;
}

class OrderRepository {
  static const _boxName = 'service_orders';
  static const _indexKey = '__index__';
  static const _activeOrderIdKey = '__active_order_id__';
  static const _activeItemIndexKey = '__active_item_index__';

  Box<String>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  void _ensureBox() {
    if (_box == null && Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<String>(_boxName);
    }
  }

  List<String> listOrderIds() {
    final raw = _box?.get(_indexKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  List<ServiceOrder> listOrders() {
    return listOrderIds()
        .map((id) => getOrder(id))
        .whereType<ServiceOrder>()
        .toList();
  }

  ServiceOrder? getOrder(String id) {
    final raw = _box?.get(id);
    if (raw == null) return null;
    return ServiceOrder.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveOrder(ServiceOrder order) async {
    await _box?.put(order.id, jsonEncode(order.toJson()));
    final ids = listOrderIds();
    if (!ids.contains(order.id)) {
      ids.add(order.id);
      await _box?.put(_indexKey, jsonEncode(ids));
    }
  }

  ActiveOrderSelection readActiveSelection() {
    _ensureBox();
    final orderId = _box?.get(_activeOrderIdKey);
    final indexRaw = _box?.get(_activeItemIndexKey);
    final itemIndex = indexRaw != null ? int.tryParse(indexRaw) ?? 0 : 0;
    return ActiveOrderSelection(
      orderId: orderId?.isNotEmpty == true ? orderId : null,
      itemIndex: itemIndex < 0 ? 0 : itemIndex,
    );
  }

  void saveActiveSelection({
    required String? orderId,
    required int itemIndex,
  }) {
    _ensureBox();
    if (_box == null) return;
    if (orderId == null) {
      _box!.delete(_activeOrderIdKey);
    } else {
      _box!.put(_activeOrderIdKey, orderId);
    }
    _box!.put(_activeItemIndexKey, itemIndex.toString());
  }
}
