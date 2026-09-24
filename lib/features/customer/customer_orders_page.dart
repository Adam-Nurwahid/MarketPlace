import 'package:flutter/material.dart';
import 'package:marketplace/core/services/order_service.dart';
import 'package:marketplace/core/services/review_service.dart';

import '../../core/utils/currency_formatter.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => CustomerOrdersPageState();
}

class CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final OrderService _orderService = OrderService();
  final ReviewService _reviewService = ReviewService();

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
      setState(() => _isLoading = true);
    }

    try {
      final orders = await _orderService.getMyOrders();
      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil pesanan: $e')),
      );
    }
  }

  Future<void> _showReviewDialog({
    required String orderId,
    required String productId,
    required String productName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ReviewDialog(
        orderId: orderId,
        productId: productId,
        productName: productName,
        reviewService: _reviewService,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review berhasil dikirim')),
      );
      _loadOrders(showLoading: false); // Refresh data pesanan
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Apakah kamu yakin ingin membatalkan pesanan ini?'),
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
      ),
    );

    if (confirm != true) return;

    try {
      await _orderService.cancelOrder(orderId: orderId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
      );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan pesanan: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
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

  String _getStoreStatus(Map<String, dynamic> order, String? storeId) {
    if (storeId == null || storeId.isEmpty) {
      return order['status'] as String? ?? 'PENDING';
    }

    final statuses = order['order_store_status'] as List<dynamic>? ?? [];
    for (final item in statuses) {
      if (item['store_id'] == storeId) {
        return item['status'] as String? ?? 'PENDING';
      }
    }

    return order['status'] as String? ?? 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('Belum ada pesanan'))
          : RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            final orderId = order['id'] as String;
            final status = order['status'] as String;
            final total = (order['total'] as num?)?.toDouble() ?? 0;
            final recipientName = order['recipient_name'] ?? '-';
            final shippingAddress = order['shipping_address'] ?? '-';
            final items = order['order_items'] as List<dynamic>? ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order: ${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    // Map item produk
                    ...items.map((item) {
                      final productName = item['product_name'] ?? '-';
                      final productId = item['product_id']?.toString() ?? '';
                      final storeId = item['store_id']?.toString();
                      final storeStatus = _getStoreStatus(order, storeId);
                      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                      final price = (item['price'] as num?)?.toDouble() ?? 0;
                      final lineTotal = (item['line_total'] as num?)?.toDouble() ?? (price * quantity);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('$productName x$quantity')),
                                Text(
                                  CurrencyFormatter.rupiah(lineTotal),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status ${item['store_name'] ?? 'Toko'}: $storeStatus',
                              style: TextStyle(
                                color: _statusColor(storeStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Tombol Review
                            if (status == 'DELIVERED' && productId.isNotEmpty)
                              FutureBuilder<bool>(
                                future: _reviewService.hasReviewed(
                                  orderId: orderId,
                                  productId: productId,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 36,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                                      onPressed: () => _showReviewDialog(
                                        orderId: orderId,
                                        productId: productId,
                                        productName: productName.toString(),
                                      ),
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
                      'Total: ${CurrencyFormatter.rupiah(total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (status == 'PENDING' || status == 'PROCESSING')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _cancelOrder(orderId),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Batalkan Pesanan'),
                        ),
                      )
                    else if (status == 'CANCELLED')
                      const Text(
                        'Pesanan dibatalkan',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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

// Widget Dialog Review Terpisah
class _ReviewDialog extends StatefulWidget {
  final String orderId;
  final String productId;
  final String productName;
  final ReviewService reviewService;

  const _ReviewDialog({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.reviewService,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.productName}'),
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
                onPressed: () => setState(() => _rating = starNumber),
                icon: Icon(
                  starNumber <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
            setState(() => _isSubmitting = true);
            try {
              await widget.reviewService.createReview(
                orderId: widget.orderId,
                productId: widget.productId,
                rating: _rating,
                comment: _commentController.text.trim().isEmpty
                    ? null
                    : _commentController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            } catch (e) {
              setState(() => _isSubmitting = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          child: _isSubmitting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Kirim'),
        ),
      ],
    );
  }
}