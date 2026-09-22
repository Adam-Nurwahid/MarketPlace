import 'package:flutter/material.dart';
import 'package:marketplace/core/services/order_service.dart';
import 'package:marketplace/core/services/review_service.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final OrderService _orderService = OrderService();

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
      final orders = await _orderService.getMyOrders();

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
          content: Text('Gagal mengambil pesanan: $e'),
        ),
      );
    }
  }

  Future<void> _showReviewDialog({
    required String orderId,
    required String productId,
    required String productName,
  }) async {
    int rating = 5;
    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Review $productName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Berikan rating:'),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;

                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = starNumber;
                          });
                        },
                        icon: Icon(
                          starNumber <= rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                        ),
                      );
                    }),
                  ),

                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Komentar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ReviewService().createReview(
                        orderId: orderId,
                        productId: productId,
                        rating: rating,
                        comment: commentController.text.trim().isEmpty
                            ? null
                            : commentController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );
                    }
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review berhasil dikirim'),
        ),
      );

      setState(() {});
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan Pesanan'),
          content: const Text(
            'Apakah kamu yakin ingin membatalkan pesanan ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _orderService.cancelOrder(
        orderId: orderId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan'),
        ),
      );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan pesanan: $e'),
        ),
      );
    }
  }

  Future<bool> _hasReviewed({
    required String orderId,
    required String productId,
  }) async {
    return await ReviewService().hasReviewed(
      orderId: orderId,
      productId: productId,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
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
            final status = order['status'] as String;

            final total = (order['total'] as num?)
                ?.toDouble() ??
                0;

            final recipientName =
                order['recipient_name'] ?? '-';

            final shippingAddress =
                order['shipping_address'] ?? '-';

            final items =
                order['order_items'] as List<dynamic>? ?? [];

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

                    Text(
                      'Status: $status',
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text('Penerima: $recipientName'),
                    Text('Alamat: $shippingAddress'),

                    const Divider(),

                    const Text(
                      'Produk:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    ...items.map((item) {
                      final productName = item['product_name'] ?? '-';

                      final productId = item['product_id']?.toString() ?? '';

                      final quantity = (item['quantity'] as num?)
                          ?.toInt() ??
                          0;

                      final price = (item['price'] as num?)
                          ?.toDouble() ??
                          0;

                      final lineTotal = (item['line_total'] as num?)
                          ?.toDouble() ??
                          (price * quantity);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$productName x$quantity',
                                  ),
                                ),
                                Text(
                                  'Rp ${lineTotal.toStringAsFixed(0)}',
                                ),
                              ],
                            ),

                            // Tombol review hanya untuk order DELIVERED
                          if (status == 'DELIVERED' && productId.isNotEmpty)
                      FutureBuilder<bool>(
                        future: _hasReviewed(
                          orderId: orderId,
                          productId: productId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 36,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final hasReviewed = snapshot.data ?? false;

                          if (hasReviewed) {
                            return const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '✓ Sudah direview',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }

                          return Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _showReviewDialog(
                                  orderId: orderId,
                                  productId: productId,
                                  productName: productName.toString(),
                                );

                                // Refresh tampilan setelah submit review
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.star),
                              label: const Text('Review'),
                            ),
                          );
                        },
                      ),
                          ],
                        ),
                      );
                    }),

                    const Divider(),

                    Text(
                      'Total: Rp ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Hanya pesanan PENDING yang bisa dibatalkan
                    if (status == 'PENDING')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _cancelOrder(orderId);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Batalkan Pesanan',
                          ),
                        ),
                      )
                    else if (status == 'CANCELLED')
                      const Text(
                        'Pesanan dibatalkan',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
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