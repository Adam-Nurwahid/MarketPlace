import 'package:flutter/material.dart';
import 'package:marketplace/core/services/admin_order_service.dart';


class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final AdminOrderService _service = AdminOrderService();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _service.getAllOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil transaksi: $e'),
        ),
      );
    }
  }

  String _formatPrice(dynamic value) {
    final price = (value as num?)?.toDouble() ?? 0;

    return 'Rp ${price.toStringAsFixed(0)}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'SHIPPED':
        return Colors.blue;
      case 'PROCESSING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seluruh Transaksi'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _orders.isEmpty
          ? const Center(
        child: Text('Belum ada transaksi'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];

          final orderId = order['id'] ?? '-';
          final userId = order['user_id'] ?? '-';
          final status = order['status'] ?? '-';
          final total = order['total'];

          final items = List<Map<String, dynamic>>.from(
            order['order_items'] ?? [],
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                'Order #${orderId.toString().substring(0, 8)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('Customer ID: $userId'),
                  Text('Total: ${_formatPrice(total)}'),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              children: [
                const Divider(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Penerima: ${order['recipient_name'] ?? '-'}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Alamat: ${order['shipping_address'] ?? '-'}',
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Produk:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      ...items.map((item) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item['product_name'] ?? '-',
                          ),
                          subtitle: Text(
                            '${item['store_name'] ?? '-'}\n'
                                'Jumlah: ${item['quantity'] ?? 0}',
                          ),
                          trailing: Text(
                            _formatPrice(item['price']),
                          ),
                        );
                      }),

                      const Divider(),

                      Text(
                        'Tanggal: ${order['created_at'] ?? '-'}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}