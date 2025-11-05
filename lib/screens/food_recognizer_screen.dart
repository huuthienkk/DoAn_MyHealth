import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/food_ai_service.dart';

class FoodRecognizerScreen extends StatefulWidget {
  const FoodRecognizerScreen({super.key});

  @override
  State<FoodRecognizerScreen> createState() => _FoodRecognizerScreenState();
}

class _FoodRecognizerScreenState extends State<FoodRecognizerScreen> {
  File? _image;
  List<dynamic> _recognitions = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _recognitions = [];
      _isLoading = true;
    });

    try {
      final results =
          await FoodAIService.instance.predictMultiple(_image!, numResults: 3);

      setState(() {
        _recognitions = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi nhận diện: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      await FoodAIService.instance.loadModel();
    } catch (e) {
      print('❌ Failed to initialize AI: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nhận diện món ăn"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hiển thị ảnh
            _image == null
                ? Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Chưa có ảnh",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 250, fit: BoxFit.cover),
                  ),

            const SizedBox(height: 20),

            // Nút chọn ảnh
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Chọn ảnh món ăn"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 20),

            // Hiển thị kết quả
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Đang nhận diện..."),
                ],
              ),

            if (_recognitions.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kết quả nhận diện:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _recognitions.length,
                        itemBuilder: (context, index) {
                          final recognition = _recognitions[index];
                          final confidence = (recognition['confidence'] * 100);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getConfidenceColor(confidence),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                recognition['label']?.toString() ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Độ tin cậy: ${confidence.toStringAsFixed(2)}%',
                              ),
                              trailing: Text(
                                '${confidence.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: _getConfidenceColor(confidence),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            if (_recognitions.isEmpty && !_isLoading && _image != null)
              const Text(
                "Không nhận diện được món ăn nào",
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 70) return Colors.green;
    if (confidence >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    FoodAIService.instance.closeModel();
    super.dispose();
  }
}
