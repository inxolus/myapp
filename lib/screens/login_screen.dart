import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  String _error = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _initDb() async {
    try {
      final db = DatabaseHelper();
      await db.database;
      if (mounted) setState(() => _isLoading = false);
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Database Error:\n$e\n\n$stack';
        });
      }
    }
  }
  Future<void> _login() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'PIN harus 4 digit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseHelper().getUserByPin(pin);
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'PIN salah';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: \$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hotel, size: 64, color: Color(0xFF1565C0)),
              const SizedBox(height: 16),
              const Text(
                'SALIGURI',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              ),
              const Text(
                'Reservation Manager',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: 'Masukkan PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: (_) => _login(),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_error, style: const TextStyle(color: Colors.red, fontSize: 14)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('MASUK', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
