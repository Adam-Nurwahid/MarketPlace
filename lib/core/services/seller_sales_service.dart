import 'package:supabase_flutter/supabase_flutter.dart';

class SellerSalesReport {
  final double totalSales;
  final int completedOrders;
  final int productsSold;
  final List<Map<String, dynamic>> topProducts;

  const SellerSalesReport({
    required this.totalSales,
    required this.completedOrders,
    required this.productsSold,
    required this.topProducts,
  });
}

class SellerSalesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<SellerSalesReport> getMySalesReport() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final response = await _supabase
        .from('order_items')
        .select('''
          product_id,
          product_name,
          quantity,
          price,
          order_id,
          orders!inner (
            status
          ),
          stores!inner (
            seller_id
          )
        ''')
        .eq('stores.seller_id', user.id)
        .eq('orders.status', 'DELIVERED');

    final rows = List<Map<String, dynamic>>.from(response);

    final orderIds = <String>{};

    double totalSales = 0;
    int productsSold = 0;

    final productStats = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final orderId = row['order_id'] as String?;
      final productId = row['product_id'] as String?;
      final productName = row['product_name'] as String? ?? '-';

      final quantity =
          (row['quantity'] as num?)?.toInt() ?? 0;

      final price =
          (row['price'] as num?)?.toDouble() ?? 0;

      if (orderId != null) {
        orderIds.add(orderId);
      }

      productsSold += quantity;
      totalSales += price * quantity;

      if (productId != null) {
        final current = productStats[productId] ??
            {
              'product_id': productId,
              'product_name': productName,
              'quantity': 0,
              'sales': 0.0,
            };

        current['quantity'] =
            (current['quantity'] as int) + quantity;

        current['sales'] =
            (current['sales'] as double) + price * quantity;

        productStats[productId] = current;
      }
    }

    final topProducts = productStats.values.toList()
      ..sort(
            (a, b) => (b['quantity'] as int)
            .compareTo(a['quantity'] as int),
      );

    return SellerSalesReport(
      totalSales: totalSales,
      completedOrders: orderIds.length,
      productsSold: productsSold,
      topProducts: topProducts.take(5).toList(),
    );
  }
}