import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email girin')));
      return;
    }
    setState(() => _sending = true);
    final auth = context.read<AuthStore>();
    final err = await auth.signInWithOtp(email);
    setState(() => _sending = false);
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email gönderildi. Gelen bağlantıyı kontrol edin.')));
    // Navigate to OTP page in case project uses OTP codes
    Navigator.push(context, MaterialPageRoute(builder: (_) => OtpPage(email: email)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending ? 'Gönderiliyor...' : 'Kodu / bağlantıyı gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpPage extends StatefulWidget {
  final String email;
  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final tokenCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = tokenCtrl.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kod girin')));
      return;
    }
    setState(() => _busy = true);
    final auth = context.read<AuthStore>();
    final err = await auth.verifyOtp(email: widget.email, token: token);
    setState(() => _busy = false);
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giriş başarılı')));
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kod Gir')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text('Email: ${widget.email}'),
            const SizedBox(height: 12),
            TextField(controller: tokenCtrl, decoration: const InputDecoration(labelText: '6 haneli kod')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _verify,
                child: Text(_busy ? 'Onaylanıyor...' : 'Kodu doğrula'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
