// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool loading = false;
  String? message;

  void signup() async {
    setState(() { loading = true; message = null; });
    try {
      final res = await AuthServices.signUp(_email.text.trim(), _password.text.trim());
      if (res?.user != null) {
        setState(() => message = 'Signed up. Verify email if required.');
      } else {
        setState(() => message = 'Check your email for verification link.');
      }
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: loading ? null : signup, child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create account')),
          if (message != null) Padding(padding: const EdgeInsets.only(top:12), child: Text(message!)),
        ]),
      ),
    );
  }
}
