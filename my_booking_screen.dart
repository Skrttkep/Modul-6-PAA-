import 'package:flutter/material.dart';
import 'package:carrental/models/booking_model.dart';
import 'package:carrental/models/payment_model.dart';
import 'package:carrental/services/booking_service.dart';
import 'package:carrental/services/payment_service.dart';
import 'package:carrental/widgets/loading_indicator.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  List<BookingModel> _bookings = [];
  List<PaymentModel> _payments = [];

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final bookings = await BookingService.getMyBookings();

      List<PaymentModel> payments = [];

      try {
        payments = await PaymentService.getPayments();
      } catch (e) {
        // ignore: avoid_print
        print('GET PAYMENTS USER ERROR: $e');
        payments = [];
      }

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _payments = payments;
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

  PaymentModel? _getPaymentByBookingId(String? bookingId) {
    if (bookingId == null || bookingId.isEmpty) return null;

    try {
      return _payments.firstWhere(
        (payment) => payment.bookingId == bookingId,
      );
    } catch (_) {
      return null;
    }
  }

  bool _hasPayment(BookingModel booking) {
    return _getPaymentByBookingId(booking.id) != null;
  }

  Future<void> _showPaymentDialog(BookingModel booking) async {
    if (booking.id == null || booking.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pesanan tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasPayment(booking)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran untuk pesanan ini sudah dikirim'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bankNameController = TextEditingController(text: 'BCA');
    final accountNumberController = TextEditingController(text: '1234567890');
    final accountNameController = TextEditingController(text: 'Budi Santoso');
    final transactionIdController = TextEditingController(
      text: 'TRX${DateTime.now().millisecondsSinceEpoch}',
    );
    final notesController = TextEditingController();

    String selectedMethod = 'transfer_bank';
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitPayment() async {
              if (bankNameController.text.trim().isEmpty ||
                  accountNumberController.text.trim().isEmpty ||
                  accountNameController.text.trim().isEmpty ||
                  transactionIdController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua data pembayaran wajib diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setDialogState(() {
                isSubmitting = true;
              });

              try {
                final payment = PaymentModel(
                  bookingId: booking.id!,
                  method: selectedMethod,
                  bankName: bankNameController.text.trim(),
                  accountNumber: accountNumberController.text.trim(),
                  accountName: accountNameController.text.trim(),
                  transactionId: transactionIdController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );

                await PaymentService.createPayment(payment);

                if (!mounted) return;

                Navigator.pop(dialogContext, true);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pembayaran berhasil dikirim'),
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
              title: const Text('Pembayaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        booking.carName ?? 'Mobil Rental',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        booking.totalPrice > 0
                            ? 'Total: Rp ${_formatPrice(booking.totalPrice)}'
                            : 'Total: -',
                        style: const TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Metode Pembayaran',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'transfer_bank',
                          child: Text('Transfer Bank'),
                        ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedMethod = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bankNameController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Nama Bank',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountNumberController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Rekening',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountNameController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pemilik Rekening',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: transactionIdController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'ID Transaksi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      enabled: !isSubmitting,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
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
                  onPressed: isSubmitting ? null : submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );

    bankNameController.dispose();
    accountNumberController.dispose();
    accountNameController.dispose();
    transactionIdController.dispose();
    notesController.dispose();

    if (result == true) {
      await _fetchData();
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
      case 'paid':
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
      case 'paid':
        return 'Dibayar';
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

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'confirmed':
      case 'approved':
      case 'success':
      case 'paid':
        return Colors.green;
      case 'rejected':
      case 'failed':
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  String _paymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'Pembayaran Terverifikasi';
      case 'confirmed':
        return 'Pembayaran Dikonfirmasi';
      case 'approved':
        return 'Pembayaran Disetujui';
      case 'success':
        return 'Pembayaran Berhasil';
      case 'paid':
        return 'Pembayaran Dibayar';
      case 'rejected':
        return 'Pembayaran Ditolak';
      case 'failed':
        return 'Pembayaran Gagal';
      case 'cancelled':
        return 'Pembayaran Dibatalkan';
      case 'pending':
      default:
        return 'Menunggu Verifikasi Pembayaran';
    }
  }

  bool _canPay(BookingModel booking) {
    final status = booking.status.toLowerCase();

    if (booking.id == null || booking.id!.isEmpty) {
      return false;
    }

    if (_hasPayment(booking)) {
      return false;
    }

    if (status == 'rejected' || status == 'cancelled' || status == 'failed') {
      return false;
    }

    return true;
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _statusColor(booking.status);
    final payment = _getPaymentByBookingId(booking.id);
    final hasPayment = payment != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            if (hasPayment) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _paymentStatusColor(payment.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        _paymentStatusColor(payment.status).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      payment.status.toLowerCase() == 'success' ||
                              payment.status.toLowerCase() == 'verified' ||
                              payment.status.toLowerCase() == 'paid'
                          ? Icons.verified_outlined
                          : Icons.hourglass_top,
                      color: _paymentStatusColor(payment.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _paymentStatusText(payment.status),
                        style: TextStyle(
                          color: _paymentStatusColor(payment.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _canPay(booking) ? () => _showPaymentDialog(booking) : null,
                icon: Icon(
                  hasPayment
                      ? Icons.hourglass_top
                      : Icons.payment,
                ),
                label: Text(
                  hasPayment ? _paymentStatusText(payment.status) : 'Bayar',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                onPressed: _fetchData,
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
                Icons.receipt_long_outlined,
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
                'Pesanan mobil yang kamu buat akan tampil di sini.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
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
        title: const Text('Pesanan Saya'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
}