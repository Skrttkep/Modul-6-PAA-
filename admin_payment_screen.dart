import 'package:flutter/material.dart';
import 'package:carrental/models/payment_model.dart';
import 'package:carrental/services/admin_payment_service.dart';
import 'package:carrental/widgets/loading_indicator.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _processingPaymentId;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await AdminPaymentService.getAllPayments();

      if (mounted) {
        setState(() {
          _payments = result;
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
    required PaymentModel payment,
    required String status,
  }) async {
    if (payment.id == null || payment.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pembayaran tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isVerify = status == 'verified';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isVerify ? 'Verifikasi Pembayaran' : 'Tolak Pembayaran'),
          content: Text(
            isVerify
                ? 'Yakin ingin memverifikasi pembayaran ini?'
                : 'Yakin ingin menolak pembayaran ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isVerify ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isVerify ? 'Verifikasi' : 'Tolak'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _processingPaymentId = payment.id;
    });

    try {
      await AdminPaymentService.updatePaymentStatus(
        paymentId: payment.id!,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVerify
                ? 'Pembayaran berhasil diverifikasi'
                : 'Pembayaran berhasil ditolak',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchPayments();
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
          _processingPaymentId = null;
        });
      }
    }
  }

  Color _statusColor(String status) {
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
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'Terverifikasi';
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
      case 'failed':
        return 'Gagal';
      case 'cancelled':
        return 'Dibatalkan';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  bool _canVerifyOrReject(PaymentModel payment) {
    final status = payment.status.toLowerCase();

    return status == 'pending' || status.isEmpty;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final statusColor = _statusColor(payment.status);
    final isProcessing = _processingPaymentId == payment.id;

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
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembayaran Rental',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Booking ID: ${payment.bookingId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          _statusText(payment.status),
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

            _buildInfoItem(
              icon: Icons.account_balance,
              label: 'Bank',
              value: payment.bankName.isEmpty ? '-' : payment.bankName,
            ),

            const SizedBox(height: 8),

            _buildInfoItem(
              icon: Icons.numbers,
              label: 'Nomor Rekening',
              value: payment.accountNumber.isEmpty ? '-' : payment.accountNumber,
            ),

            const SizedBox(height: 8),

            _buildInfoItem(
              icon: Icons.person_outline,
              label: 'Nama Pemilik',
              value: payment.accountName.isEmpty ? '-' : payment.accountName,
            ),

            const SizedBox(height: 8),

            _buildInfoItem(
              icon: Icons.receipt_long,
              label: 'ID Transaksi',
              value: payment.transactionId.isEmpty ? '-' : payment.transactionId,
            ),

            const SizedBox(height: 8),

            _buildInfoItem(
              icon: Icons.payment,
              label: 'Metode',
              value: payment.method.isEmpty ? '-' : payment.method,
            ),

            const SizedBox(height: 8),

            _buildInfoItem(
              icon: Icons.calendar_today,
              label: 'Tanggal',
              value: _formatDate(payment.createdAt),
            ),

            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                icon: Icons.note_alt_outlined,
                label: 'Catatan',
                value: payment.notes!,
              ),
            ],

            const SizedBox(height: 14),

            if (isProcessing)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_canVerifyOrReject(payment))
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(
                        payment: payment,
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
                        payment: payment,
                        status: 'verified',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Verifikasi'),
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
                  'Status pembayaran: ${_statusText(payment.status)}',
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
      return const LoadingIndicator(message: 'Memuat pembayaran...');
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
                onPressed: _fetchPayments,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Pembayaran user akan tampil di sini.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPayments,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          final payment = _payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
}