import 'package:flutter/material.dart';
import 'package:carrental/models/car_model.dart';
import 'package:carrental/models/booking_model.dart';
import 'package:carrental/services/booking_service.dart';
import 'package:carrental/widgets/custom_text_field.dart';
import 'package:carrental/widgets/loading_indicator.dart';

class BookingFormScreen extends StatefulWidget {
  final CarModel car;

  const BookingFormScreen({
    super.key,
    required this.car,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _pickupLocationController = TextEditingController();
  final _returnLocationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;

    final difference = _endDate!.difference(_startDate!).inDays;

    if (difference <= 0) return 1;

    return difference;
  }

  double get _totalPrice {
    return _totalDays * widget.car.pricePerDay;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';

    return '${date.day}/${date.month}/${date.year}';
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

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;

        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final firstDate = _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai sewa harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai sewa harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.car.id == null || widget.car.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID mobil tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final booking = BookingModel(
        carId: widget.car.id!,
        startDate: _startDate!,
        endDate: _endDate!,
        pickupLocation: _pickupLocationController.text.trim(),
        returnLocation: _returnLocationController.text.trim(),
        totalDays: _totalDays,
        totalPrice: _totalPrice,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await BookingService.createBooking(booking);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemesanan berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCarSummary(CarModel car) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
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
                            size: 42,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.directions_car,
                      size: 42,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.brand} ${car.model} • ${car.year}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.transmission} • ${car.fuelType} • ${car.seats} kursi',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${_formatPrice(car.pricePerDay)}/hari',
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.bold,
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

  Widget _buildDatePickerBox({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostSummary(CarModel car) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Biaya',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lama sewa'),
              Text('$_totalDays hari'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Harga per hari'),
              Text('Rp ${_formatPrice(car.pricePerDay)}'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rp ${_formatPrice(_totalPrice)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _returnLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemesanan Mobil'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Membuat pemesanan...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCarSummary(car),

                    const SizedBox(height: 20),

                    const Text(
                      'Tanggal Sewa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _buildDatePickerBox(
                          icon: Icons.calendar_today,
                          text: _formatDate(_startDate),
                          onTap: _pickStartDate,
                        ),
                        const SizedBox(width: 12),
                        _buildDatePickerBox(
                          icon: Icons.event_available,
                          text: _formatDate(_endDate),
                          onTap: _pickEndDate,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    CustomTextField(
                      label: 'Lokasi Pengambilan',
                      controller: _pickupLocationController,
                      prefixIcon: Icons.location_on_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lokasi pengambilan wajib diisi';
                        }

                        return null;
                      },
                    ),

                    CustomTextField(
                      label: 'Lokasi Pengembalian',
                      controller: _returnLocationController,
                      prefixIcon: Icons.location_city_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lokasi pengembalian wajib diisi';
                        }

                        return null;
                      },
                    ),

                    CustomTextField(
                      label: 'Catatan',
                      controller: _notesController,
                      prefixIcon: Icons.note_alt_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 10),

                    _buildCostSummary(car),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Buat Pemesanan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}