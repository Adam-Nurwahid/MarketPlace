import 'package:flutter/material.dart';
import 'package:marketplace/core/services/address_service.dart';
import 'package:marketplace/core/services/cart_service.dart';
import 'package:marketplace/features/customer/payment_page.dart';


class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final AddressService _addressService = AddressService();
  final CartService _cartService = CartService();

  List<Map<String, dynamic>> addresses = [];

  String? selectedAddressId;

  bool isLoading = true;
  bool isProcessing = false;

  final recipientNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressLineController = TextEditingController();
  final cityController = TextEditingController();
  final provinceController = TextEditingController();
  final postalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    recipientNameController.dispose();
    phoneController.dispose();
    addressLineController.dispose();
    cityController.dispose();
    provinceController.dispose();
    postalCodeController.dispose();

    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final result = await _addressService.getMyAddresses();

      setState(() {
        addresses = result;

        if (addresses.isNotEmpty) {
          selectedAddressId = addresses.first['id'].toString();
        }
      });
    } catch (e) {
      _showMessage('Gagal memuat alamat: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addAddress() async {
    if (recipientNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressLineController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        provinceController.text.trim().isEmpty ||
        postalCodeController.text.trim().isEmpty) {
      _showMessage('Semua kolom alamat wajib diisi');
      return;
    }

    try {
      await _addressService.createAddress(
        recipientName: recipientNameController.text.trim(),
        phone: phoneController.text.trim(),
        addressLine: addressLineController.text.trim(),
        city: cityController.text.trim(),
        province: provinceController.text.trim(),
        postalCode: postalCodeController.text.trim(),
      );

      recipientNameController.clear();
      phoneController.clear();
      addressLineController.clear();
      cityController.clear();
      provinceController.clear();
      postalCodeController.clear();

      Navigator.pop(context);

      await _loadAddresses();

      _showMessage('Alamat berhasil ditambahkan');
    } catch (e) {
      _showMessage('Gagal menambahkan alamat: $e');
    }
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Alamat'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: recipientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penerima',
                  ),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                  ),
                ),
                TextField(
                  controller: addressLineController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap',
                  ),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'Kota',
                  ),
                ),
                TextField(
                  controller: provinceController,
                  decoration: const InputDecoration(
                    labelText: 'Provinsi',
                  ),
                ),
                TextField(
                  controller: postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Pos',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _addAddress,
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkout() async {
    if (selectedAddressId == null) {
      _showMessage('Pilih alamat terlebih dahulu');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final cartItems = await _cartService.getCartItems();

      final cartSnapshot = cartItems.map((item) {
        return {
          'product_id': item['product_id'],
          'quantity': item['quantity'],
        };
      }).toList();
      final orderId = await _cartService.checkout(
        addressId: selectedAddressId!,
      );

      if (!mounted) return;

      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            orderId: orderId,
            cartItems: cartSnapshot,
          ),
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, paymentResult == true);
    } catch (e) {
      _showMessage('Checkout gagal: $e');
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
        title: const Text('Checkout'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alamat Pengiriman',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (addresses.isEmpty)
              const Text('Belum ada alamat tersimpan')
            else
              DropdownButtonFormField<String>(
                value: selectedAddressId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Pilih Alamat',
                ),
                items: addresses.map((address) {
                  final id = address['id'].toString();

                  final label =
                      '${address['recipient_name']} - '
                      '${address['city']}';

                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAddressId = value;
                  });
                },
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Tambah Alamat'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _checkout,
                child: isProcessing
                    ? const CircularProgressIndicator()
                    : const Text('Buat Pesanan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}