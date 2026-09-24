import 'package:flutter/material.dart';

import '../../core/services/seller_sales_service.dart';

class SellerSalesReportPage extends StatefulWidget {
  const SellerSalesReportPage({super.key});

  @override
  State<SellerSalesReportPage> createState() =>
      _SellerSalesReportPageState();
}

class _SellerSalesReportPageState
    extends State<SellerSalesReportPage> {
  final SellerSalesService _service = SellerSalesService();

  SellerSalesReport? _report;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await _service.getMySalesReport();

      if (!mounted) return;

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double value) {
    final rounded = value.round().toString();

    final chars = rounded.split('').reversed.toList();

    final groups = <String>[];

    for (var i = 0; i < chars.length; i += 3) {
      groups.add(
        chars
            .skip(i)
            .take(3)
            .toList()
            .reversed
            .join(),
      );
    }

    return 'Rp ${groups.reversed.join('.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal mengambil laporan:\n$_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReport,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final report = _report!;

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Ringkasan Penjualan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
              constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth >= 600
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _summaryCard(
                    width: cardWidth,
                    icon: Icons.payments_outlined,
                    title: 'Total Penjualan',
                    value: _formatRupiah(
                      report.totalSales,
                    ),
                  ),
                  _summaryCard(
                    width: cardWidth,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Pesanan Selesai',
                    value:
                    '${report.completedOrders}',
                  ),
                  _summaryCard(
                    width: cardWidth,
                    icon: Icons.inventory_2_outlined,
                    title: 'Produk Terjual',
                    value:
                    '${report.productsSold}',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          const Text(
            'Produk Terlaris',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (report.topProducts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada penjualan yang selesai.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (
                  var i = 0;
                  i < report.topProducts.length;
                  i++
                  )
                    ListTile(
                      leading: CircleAvatar(
                        child: Text('${i + 1}'),
                      ),
                      title: Text(
                        report.topProducts[i]
                        ['product_name'] as String,
                      ),
                      subtitle: Text(
                        '${report.topProducts[i]['quantity']} '
                            'unit terjual',
                      ),
                      trailing: Text(
                        _formatRupiah(
                          report.topProducts[i]['sales']
                          as double,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required double width,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}