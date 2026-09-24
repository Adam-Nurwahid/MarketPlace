import 'package:flutter/material.dart';
import 'package:marketplace/core/services/seller_order_service.dart';

import '../../core/utils/currency_formatter.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => SellerOrdersPageState();
}

class SellerOrdersPageState extends State<SellerOrdersPage> {
  final SellerOrderService _orderService = SellerOrderService();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void refreshOrders() {
    _loadOrders(showLoading: false);
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final orders = await _orderService.getMyOrders();

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil pesanan: $e'),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(
      String orderId,
      String storeId,
      String currentStatus,
      ) async {
    String? nextStatus;

    if (currentStatus == 'PENDING') {
      nextStatus = 'PROCESSING';
    } else if (currentStatus == 'PROCESSING') {
      nextStatus = 'SHIPPED';
    } else if (currentStatus == 'SHIPPED') {
      nextStatus = 'DELIVERED';
    }

    if (nextStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status pesanan tidak dapat diubah'),
        ),
      );

      return;
    }

    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        storeId: storeId,
        newStatus: nextStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status toko diubah menjadi $nextStatus',
            ),
          ),
        );

        await _loadOrders(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengubah status: $e',
            ),
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;

      case 'PROCESSING':
        return Colors.blue;

      case 'SHIPPED':
        return Colors.purple;

      case 'DELIVERED':
        return Colors.green;

      case 'CANCELLED':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String _buttonLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Proses Pesanan';

      case 'PROCESSING':
        return 'Kirim Pesanan';

      case 'SHIPPED':
        return 'Tandai Diterima';

      default:
        return 'Ubah Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pesanan Masuk'),
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
        child: Text('Belum ada pesanan'),
      )
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];

            final orderId = order['id'] as String;

            // PENTING:
            // Sekarang seller menggunakan status milik tokonya.
            final status =
                order['seller_status'] as String? ??
                    order['status'] as String;

            final storeId =
            order['seller_store_id'] as String;

            final totalAmount =
                (order['total'] as num?)?.toDouble() ?? 0;

            final items =
                order['order_items'] as List<dynamic>? ?? [];

            final sellerItems = items.where((item) {
              return item['store_id'] == storeId;
            }).toList();

            final recipientName =
                order['recipient_name'] ?? '-';

            final phone =
                order['phone'] ?? '-';

            final shippingAddress =
                order['shipping_address'] ?? '-';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order: ${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status)
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Status Toko: $status',
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Customer: $recipientName',
                    ),
                    Text(
                      'Telepon: $phone',
                    ),
                    Text(
                      'Alamat: $shippingAddress',
                    ),

                    const SizedBox(height: 8),
                    const Divider(),

                    const Text(
                      'Produk Toko:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    ...sellerItems.map((item) {
                      final productName =
                          item['product_name'] ?? '-';

                      final price =
                          (item['price'] as num?)
                              ?.toDouble() ??
                              0;

                      final quantity =
                          (item['quantity'] as num?)
                              ?.toInt() ??
                              0;

                      final subtotal =
                          (item['line_total'] as num?)
                              ?.toDouble() ??
                              0;

                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  '${productName} x$quantity @${CurrencyFormatter.rupiah(price)}',
                              ),
                            ),
                            Text(
                                CurrencyFormatter.rupiah(subtotal)
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(),

                    Text(
                   'Total Order: ${CurrencyFormatter.rupiah(totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (status == 'PENDING' ||
                        status == 'PROCESSING' ||
                        status == 'SHIPPED')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _updateStatus(
                              orderId,
                              storeId,
                              status,
                            );
                          },
                          child: Text(
                            _buttonLabel(status),
                          ),
                        ),
                      )
                    else if (status == 'DELIVERED')
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Pesanan toko telah selesai',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (status == 'CANCELLED')
                        const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Pesanan dibatalkan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
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