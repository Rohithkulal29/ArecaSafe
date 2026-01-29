// lib/screens/image_prediction.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ImagePredictionScreen extends StatefulWidget {
  const ImagePredictionScreen({super.key});
  @override
  State<ImagePredictionScreen> createState() => _ImagePredictionScreenState();
}

class _ImagePredictionScreenState extends State<ImagePredictionScreen> {
  File? _image;
  String? _result;
  bool loading = false;

  Future<void> pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p == null) return;
    setState(() => _image = File(p.path));
  }

  Future<void> predict() async {
    if (_image == null) return;
    setState(() { loading = true; _result = null; });
    final res = await ApiService.uploadImage(_image!.path);
    setState(() {
      _result = res == null ? "Error" : res.toString();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      ElevatedButton(onPressed: pickImage, child: const Text("Pick image")),
      if (_image != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Image.file(_image!, height: 220)),
      ElevatedButton(onPressed: loading ? null : predict, child: const Text("Predict")),
      const SizedBox(height: 12),
      if (loading) const CircularProgressIndicator(),
      if (_result != null) SelectableText("Result: $_result"),
    ]);
  }
}
