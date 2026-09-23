import 'package:flutter/material.dart';
import 'package:marketplace/core/services/order_service.dart';


class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderService _orderService = OrderService();

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final result = await _orderService.getMyOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
      });
    } catch (e) {
      _showMessage('Gagal memuat pesanan: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatPrice(dynamic value) {
    final price = double.parse(value.toString());
    return 'Rp ${price.toStringAsFixed(0)}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PROCESSING':
        return Colors.orange;
      case 'SHIPPED':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.grey;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    final items = List<Map<String, dynamic>>.from(
      order['order_items'] ?? [],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detail Pesanan'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${order['id']}'),
                  const SizedBox(height: 12),
                  Text(
                    'Penerima: ${order['recipient_name'] ?? '-'}',
                  ),
                  Text(
                    'Alamat: ${order['shipping_address'] ?? '-'}',
                  ),
                  const Divider(),
                  const Text(
                    'Produk',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final name = item['product_name'] ?? '-';
                    final store = item['store_name'] ?? '-';
                    final quantity = item['quantity'] ?? 0;
                    final price = item['price'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$name\n'
                            'Toko: $store\n'
                            'Jumlah: $quantity\n'
                            'Harga: ${_formatPrice(price)}',
                      ),
                    );
                  }),
                  const Divider(),
                  Text(
                    'Total: ${_formatPrice(order['total'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pesanan Saya'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : orders.isEmpty
          ? const Center(
        child: Text('Belum ada pesanan'),
      )
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            final status = order['status'] ?? 'PENDING';
            final createdAt = order['created_at'] ?? '-';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order['id'].toString().substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tanggal: $createdAt'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status Order'),
                        Chip(
                          label: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor:
                          _statusColor(status),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ${_formatPrice(order['total'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _showOrderDetail(order);
                        },
                        child: const Text('Lihat Detail'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}