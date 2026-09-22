import 'package:flutter/material.dart';
import 'package:marketplace/core/services/payment_service.dart';


class PaymentPage extends StatefulWidget {
  final String orderId;

  const PaymentPage({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();

  bool isProcessing = false;

  Future<void> _processPayment(bool success) async {
    setState(() {
      isProcessing = true;
    });

    try {
      await _paymentService.simulatePayment(
        orderId: widget.orderId,
        success: success,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              success ? 'Pembayaran Berhasil' : 'Pembayaran Gagal',
            ),
            content: Text(
              success
                  ? 'Pembayaran pesanan berhasil disimulasikan.'
                  : 'Pembayaran pesanan gagal disimulasikan.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Pembayaran gagal diproses: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulasi Pembayaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pembayaran Pesanan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Order ID:\n${widget.orderId}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
            const Text(
              'Pilih hasil simulasi pembayaran:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => _processPayment(true),
                icon: const Icon(Icons.check_circle),
                label: const Text('Pembayaran Berhasil'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => _processPayment(false),
                icon: const Icon(Icons.cancel),
                label: const Text('Pembayaran Gagal'),
              ),
            ),
            if (isProcessing) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}