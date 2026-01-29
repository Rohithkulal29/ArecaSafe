// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'signup_screen.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool loading = false;
  String? error;

  void login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await AuthServices.signIn(_email.text.trim(), _password.text.trim());
      // If signIn returns a session -> go to main home
      final session = res?.session;
      if (session != null) {
        // rebuild by navigating to root home
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ArecaSafeApp()));
      } else {
        setState(() => error = "Login failed. Check credentials.");
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ArecaSafe")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: loading ? null : login, child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Login")),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text("Create account"))
          ],
        ),
      ),
    );
  }
}
