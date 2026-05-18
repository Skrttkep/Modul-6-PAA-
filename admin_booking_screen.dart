import 'package:flutter/material.dart';
import 'package:carrental/models/booking_model.dart';
import 'package:carrental/services/admin_booking_service.dart';
import 'package:carrental/widgets/loading_indicator.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _processingBookingId;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await AdminBookingService.getAllBookings();

      if (mounted) {
        setState(() {
          _bookings = result;
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

  Future<void> _updateStatus({
    required BookingModel booking,
    required String status,
  }) async {
    if (booking.id == null || booking.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pesanan tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isConfirm = status == 'confirmed';

        return AlertDialog(
          title: Text(isConfirm ? 'Konfirmasi Pesanan' : 'Tolak Pesanan'),
          content: Text(
            isConfirm
                ? 'Yakin ingin mengonfirmasi pesanan ini?'
                : 'Yakin ingin menolak pesanan ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConfirm ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isConfirm ? 'Konfirmasi' : 'Tolak'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _processingBookingId = booking.id;
    });

    try {
      await AdminBookingService.updateBookingStatus(
        bookingId: booking.id!,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed'
                ? 'Pesanan berhasil dikonfirmasi'
                : 'Pesanan berhasil ditolak',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchBookings();
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
        setState(() {
          _processingBookingId = null;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
      case 'success':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
      case 'failed':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'approved':
        return 'Disetujui';
      case 'success':
        return 'Berhasil';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      case 'failed':
        return 'Gagal';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  bool _canConfirmOrReject(BookingModel booking) {
    final status = booking.status.toLowerCase();

    return status == 'pending';
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _statusColor(booking.status);
    final isProcessing = _processingBookingId == booking.id;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: booking.carImage != null &&
                          booking.carImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            booking.carImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.directions_car,
                                size: 36,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.directions_car,
                          size: 36,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.carName ?? 'Mobil Rental',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.carBrand ?? 'Detail mobil',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusText(booking.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Mulai',
                    value: _formatDate(booking.startDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.event_available,
                    label: 'Selesai',
                    value: _formatDate(booking.endDate),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.timer_outlined,
                    label: 'Lama Sewa',
                    value: '${booking.totalDays} hari',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.payments_outlined,
                    label: 'Total',
                    value: booking.totalPrice > 0
                        ? 'Rp ${_formatPrice(booking.totalPrice)}'
                        : '-',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildInfoItem(
              icon: Icons.location_on_outlined,
              label: 'Lokasi Ambil',
              value: booking.pickupLocation.isEmpty
                  ? '-'
                  : booking.pickupLocation,
            ),

            const SizedBox(height: 8),

            _buildInfoItem(
              icon: Icons.location_city_outlined,
              label: 'Lokasi Kembali',
              value: booking.returnLocation.isEmpty
                  ? '-'
                  : booking.returnLocation,
            ),

            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                icon: Icons.note_alt_outlined,
                label: 'Catatan',
                value: booking.notes!,
              ),
            ],

            const SizedBox(height: 14),

            if (isProcessing)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_canConfirmOrReject(booking))
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(
                        booking: booking,
                        status: 'rejected',
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(
                        booking: booking,
                        status: 'confirmed',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Konfirmasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Text(
                  'Status pesanan: ${_statusText(booking.status)}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat pesanan...');
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
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchBookings,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Data pesanan user akan tampil di sini.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
}