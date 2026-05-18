import 'package:flutter/material.dart';
import 'package:carrental/models/car_model.dart';
import 'package:carrental/services/car_service.dart';
import 'package:carrental/widgets/loading_indicator.dart';

class AdminCarScreen extends StatefulWidget {
  const AdminCarScreen({super.key});

  @override
  State<AdminCarScreen> createState() => _AdminCarScreenState();
}

class _AdminCarScreenState extends State<AdminCarScreen> {
  List<CarModel> _cars = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  Future<void> _fetchCars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await CarService.getCars();

      if (mounted) {
        setState(() {
          _cars = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddCarDialog() async {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController(text: '2024');
    final priceController = TextEditingController(text: '300000');
    final imageController = TextEditingController(
      text:
          'https://images.unsplash.com/photo-1549924231-f129b911e442?w=800',
    );
    final descriptionController = TextEditingController();

    String transmission = 'automatic';
    String fuelType = 'bensin';
    int seats = 4;
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitCar() async {
              final year = int.tryParse(yearController.text.trim()) ?? 0;
              final price = double.tryParse(priceController.text.trim()) ?? 0;

              if (nameController.text.trim().isEmpty ||
                  brandController.text.trim().isEmpty ||
                  modelController.text.trim().isEmpty ||
                  year <= 0 ||
                  price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama, brand, model, tahun, dan harga wajib valid'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setDialogState(() {
                isSubmitting = true;
              });

              try {
                final car = CarModel(
                  name: nameController.text.trim(),
                  brand: brandController.text.trim(),
                  model: modelController.text.trim(),
                  year: year,
                  pricePerDay: price,
                  image: imageController.text.trim(),
                  description: descriptionController.text.trim(),
                  transmission: transmission,
                  fuelType: fuelType,
                  seats: seats,
                  status: 'available',
                );

                await CarService.createCar(car);

                if (!mounted) return;

                Navigator.pop(dialogContext, true);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mobil berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                setDialogState(() {
                  isSubmitting = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Tambah Mobil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Nama Mobil',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: brandController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: yearController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tahun',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga per Hari',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: transmission,
                      decoration: const InputDecoration(
                        labelText: 'Transmisi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'automatic',
                          child: Text('Automatic'),
                        ),
                        DropdownMenuItem(
                          value: 'manual',
                          child: Text('Manual'),
                        ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  transmission = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: fuelType,
                      decoration: const InputDecoration(
                        labelText: 'Bahan Bakar',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'bensin',
                          child: Text('Bensin'),
                        ),
                        DropdownMenuItem(
                          value: 'diesel',
                          child: Text('Diesel'),
                        ),
                        DropdownMenuItem(
                          value: 'electric',
                          child: Text('Electric'),
                        ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  fuelType = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: seats,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Kursi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('2 Kursi')),
                        DropdownMenuItem(value: 4, child: Text('4 Kursi')),
                        DropdownMenuItem(value: 5, child: Text('5 Kursi')),
                        DropdownMenuItem(value: 7, child: Text('7 Kursi')),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  seats = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      enabled: !isSubmitting,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (isSubmitting) ...[
                      const SizedBox(height: 18),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitCar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    priceController.dispose();
    imageController.dispose();
    descriptionController.dispose();

    if (result == true) {
      await _fetchCars();
    }
  }

  String _formatPrice(double price) {
    final priceStr = price.toStringAsFixed(0);
    String result = '';
    int count = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      count++;
      result = priceStr[i] + result;

      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }

    return result;
  }

  Widget _buildCarCard(CarModel car) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: car.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        car.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.directions_car,
                            size: 38,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.directions_car,
                      size: 38,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.brand} ${car.model} • ${car.year}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${_formatPrice(car.pricePerDay)} / hari',
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${car.transmission} • ${car.fuelType} • ${car.seats} kursi',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat data mobil...');
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchCars,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada mobil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Klik tombol + untuk menambahkan data mobil.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCars,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 90),
        itemCount: _cars.length,
        itemBuilder: (context, index) {
          return _buildCarCard(_cars[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Mobil'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCarDialog,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Mobil'),
      ),
    );
  }
}