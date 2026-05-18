import 'package:flutter/material.dart';
import 'package:carrental/services/auth_service.dart';
import 'package:carrental/screens/home_screen.dart';
import 'package:carrental/screens/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String _extractRole(dynamic result) {
    try {
      if (result == null) return '';

      if (result is Map<String, dynamic>) {
        if (result['role'] != null) {
          return result['role'].toString().toLowerCase();
        }

        if (result['user'] is Map<String, dynamic>) {
          final user = result['user'] as Map<String, dynamic>;
          return user['role']?.toString().toLowerCase() ?? '';
        }

        if (result['data'] is Map<String, dynamic>) {
          final data = result['data'] as Map<String, dynamic>;

          if (data['role'] != null) {
            return data['role'].toString().toLowerCase();
          }

          if (data['user'] is Map<String, dynamic>) {
            final user = data['user'] as Map<String, dynamic>;
            return user['role']?.toString().toLowerCase() ?? '';
          }
        }
      }

      final role = result.role;
      return role?.toString().toLowerCase() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      final role = _extractRole(result);
      final email = _emailController.text.trim().toLowerCase();

      // Debug terminal
      // ignore: avoid_print
      print('LOGIN RESULT: $result');
      // ignore: avoid_print
      print('LOGIN ROLE: $role');
      // ignore: avoid_print
      print('LOGIN EMAIL: $email');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          backgroundColor: Colors.green,
        ),
      );

      if (role == 'admin' || email.contains('admin')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminHomeScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_filled,
            color: Colors.white,
            size: 46,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Rental Mobil',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Login untuk melanjutkan',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Masukkan email',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF1A1A2E),
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email wajib diisi';
        }

        if (!value.contains('@')) {
          return 'Format email tidak valid';
        }

        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Masukkan password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF1A1A2E),
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Password wajib diisi';
        }

        if (value.length < 6) {
          return 'Password minimal 6 karakter';
        }

        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text('Login'),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Login admin akan masuk ke Dashboard Admin. Login user akan masuk ke halaman Rental Mobil.',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                _buildLogo(),
                const SizedBox(height: 34),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 20),
                        _buildLoginButton(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildInfoBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}