import 'package:flutter/material.dart';

import '../../core/services/product_service.dart';
import '../../core/utils/currency_formatter.dart';
import 'product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _products = [];

  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedStoreId;
  String _selectedSort = 'default';

  // --- Konfigurasi grid produk ---
  // maxCrossAxisExtent: lebar MAKSIMAL satu card. Semakin lebar layar (web/tablet),
  // jumlah kolom akan otomatis bertambah, sehingga card & gambar tidak ikut membesar.
  static const double _cardMaxWidth = 190;
  static const double _cardHeight = 258;
  static const double _productImageHeight = 100;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getProducts();

      if (!mounted) return;

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();

    List<Map<String, dynamic>> filtered =
    List<Map<String, dynamic>>.from(_allProducts);

    if (keyword.isNotEmpty) {
      filtered = filtered.where((product) {
        final productName = (product['name'] ?? '').toString().toLowerCase();
        final storeData = product['stores'];
        final storeName = storeData is Map
            ? (storeData['name'] ?? '').toString().toLowerCase()
            : '';

        return productName.contains(keyword) || storeName.contains(keyword);
      }).toList();
    }

    if (_selectedStoreId != null) {
      filtered = filtered.where((product) {
        final storeData = product['stores'];

        if (storeData is! Map) {
          return false;
        }

        return storeData['id']?.toString() == _selectedStoreId;
      }).toList();
    }

    switch (_selectedSort) {
      case 'price_low':
        filtered.sort((a, b) {
          final priceA = double.tryParse(a['price'].toString()) ?? 0;
          final priceB = double.tryParse(b['price'].toString()) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;

      case 'price_high':
        filtered.sort((a, b) {
          final priceA = double.tryParse(a['price'].toString()) ?? 0;
          final priceB = double.tryParse(b['price'].toString()) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;

      case 'name':
        filtered.sort((a, b) {
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });
        break;
    }

    setState(() {
      _products = filtered;
    });
  }

  List<Map<String, dynamic>> _getStores() {
    final Map<String, Map<String, dynamic>> stores = {};

    for (final product in _allProducts) {
      final storeData = product['stores'];

      if (storeData is Map) {
        final storeId = storeData['id']?.toString();

        if (storeId != null && storeId.isNotEmpty) {
          stores[storeId] = {
            'id': storeId,
            'name': storeData['name']?.toString() ?? 'Toko',
          };
        }
      }
    }

    final result = stores.values.toList();

    result.sort(
          (a, b) => a['name']
          .toString()
          .toLowerCase()
          .compareTo(b['name'].toString().toLowerCase()),
    );

    return result;
  }

  void _showFilterBottomSheet() {
    String? temporaryStoreId = _selectedStoreId;
    String temporarySort = _selectedSort;

    final stores = _getStores();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter & Urutkan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Toko',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: temporaryStoreId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelText: 'Pilih toko',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Toko'),
                        ),
                        ...stores.map((store) {
                          return DropdownMenuItem<String?>(
                            value: store['id'].toString(),
                            child: Text(store['name'].toString()),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          temporaryStoreId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Urutkan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: temporarySort,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelText: 'Urutkan berdasarkan',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'default', child: Text('Default')),
                        DropdownMenuItem(value: 'price_low', child: Text('Harga terendah')),
                        DropdownMenuItem(value: 'price_high', child: Text('Harga tertinggi')),
                        DropdownMenuItem(value: 'name', child: Text('Nama A-Z')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          temporarySort = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                temporaryStoreId = null;
                                temporarySort = 'default';
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedStoreId = temporaryStoreId;
                                _selectedSort = temporarySort;
                              });

                              Navigator.pop(context);
                              _applyFilters();
                            },
                            child: const Text('Terapkan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getSelectedStoreName() {
    if (_selectedStoreId == null) {
      return 'Semua Toko';
    }

    final stores = _getStores();

    for (final store in stores) {
      if (store['id'].toString() == _selectedStoreId) {
        return store['name'].toString();
      }
    }

    return 'Semua Toko';
  }

  String _getSortLabel() {
    switch (_selectedSort) {
      case 'price_low':
        return 'Harga terendah';
      case 'price_high':
        return 'Harga tertinggi';
      case 'name':
        return 'Nama A-Z';
      default:
        return 'Default';
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter =
        _selectedStoreId != null || _selectedSort != 'default';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Marketplace',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Search Input ringkas & terstandardisasi
            SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  hintText: 'Cari produk atau toko',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clearSearch,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Button Filter Compact
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.tune, size: 16),
                label: Text(
                  hasActiveFilter
                      ? 'Filter: ${_getSelectedStoreName()} • ${_getSortLabel()}'
                      : 'Filter & Urutkan',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_products.length} produk ditemukan',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildProductContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    // Tinggi gambar TETAP (tidak lagi memakai AspectRatio yang ikut
    // membesar mengikuti lebar kolom) — supaya ukuran gambar konsisten
    // baik di layar mobile kecil maupun di web yang lebar.
    return SizedBox(
      height: _productImageHeight,
      width: double.infinity,
      child: Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: imagePath == null || imagePath.isEmpty
            ? const Icon(
          Icons.shopping_bag_outlined,
          size: 28,
          color: Colors.grey,
        )
            : _buildNetworkImage(imagePath),
      ),
    );
  }

  Widget _buildNetworkImage(String imagePath) {
    final imageUrl = _productService.getProductImageUrl(imagePath);

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: Colors.grey,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _buildProductContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Terjadi kesalahan:\n$_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'Produk tidak ditemukan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    // Grid responsif: lebar card dibatasi (maxCrossAxisExtent), jumlah kolom
    // otomatis menyesuaikan lebar layar — 2 kolom di HP kecil, lebih banyak
    // kolom di tablet/web tanpa membuat card & gambar ikut membesar.
    // Tinggi card (mainAxisExtent) dibuat tetap agar tidak ada sisa ruang
    // kosong seperti saat memakai childAspectRatio manual sebelumnya.
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _cardMaxWidth,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: _cardHeight,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final storeData = product['stores'];
        final storeName = storeData is Map ? storeData['name'] ?? 'Toko' : 'Toko';

        return Card(
          elevation: 1.5,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisSize default (max): Column mengisi penuh tinggi card
              // (mainAxisExtent), lalu Spacer() di bawah menyerap sisa ruang
              // sehingga tombol tetap menempel rapi di bawah, tanpa blank
              // space besar seperti sebelumnya.
              children: [
                _buildProductImage(product['image_path']?.toString()),
                const SizedBox(height: 6),

                // Judul Produk
                Text(
                  product['name'] ?? 'Produk',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),

                // Nama Toko
                Text(
                  storeName.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),

                // Harga Produk
                Text(
                  CurrencyFormatter.rupiah(product['price']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),

                // Stok Produk
                Text(
                  'Stok: ${product['stock']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),

                // Menyerap sisa ruang vertikal (jika ada) agar tombol
                // tetap rapi di bawah, bukan menyisakan blank space.
                const Spacer(),

                // Tombol Detail/Lihat Produk (Compact & Rapi)
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            product: product,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Produk',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}