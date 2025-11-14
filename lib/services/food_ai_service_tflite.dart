import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';  // Tạm thời comment do lỗi tương thích

class FoodAIServiceTFLite {
  static final FoodAIServiceTFLite _instance = FoodAIServiceTFLite._internal();
  factory FoodAIServiceTFLite() => _instance;
  FoodAIServiceTFLite._internal();

  static FoodAIServiceTFLite get instance => _instance;

  // Interpreter? _interpreter;  // Tạm thời comment do lỗi tương thích
  dynamic _interpreter;  // Sử dụng dynamic để tránh lỗi compile
  List<String> _labels = [];
  bool _isModelLoaded = false;

  // Calorie database (ước tính calo cho từng món ăn)
  final Map<String, double> _calorieDatabase = {
    'Pizza': 266.0, // calo/100g
    'Burger': 295.0,
    'Salad': 20.0,
    'Pasta': 131.0,
    'Sushi': 150.0,
    'Ramen': 436.0,
    'Steak': 271.0,
    'Sandwich': 250.0,
    'Taco': 226.0,
    'Rice': 130.0,
    'Soup': 50.0,
    'Chicken': 239.0,
    'Fish': 206.0,
    'Fruit': 60.0,
    'Vegetables': 25.0,
  };

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      // Load labels
      try {
        final labelContent = await rootBundle.loadString('assets/labels.txt');
        _labels = labelContent
            .split('\n')
            .where((label) => label.trim().isNotEmpty)
            .toList();
        debugPrint('✅ Loaded ${_labels.length} labels from file');
      } catch (e) {
        debugPrint('⚠️ Using default labels');
        _labels = _calorieDatabase.keys.toList();
      }

      // Load model - Tạm thời disable do lỗi tương thích với tflite_flutter
      try {
        // _interpreter = await Interpreter.fromAsset('assets/food_model.tflite');
        // 
        // // Get input/output shapes
        // final inputShape = _interpreter!.getInputTensor(0).shape;
        // final outputShape = _interpreter!.getOutputTensor(0).shape;
        // 
        // debugPrint('✅ Model loaded - Input: $inputShape, Output: $outputShape');
        // _isModelLoaded = true;
        
        // Tạm thời sử dụng mock mode
        debugPrint('⚠️ TFLite temporarily disabled due to compatibility issues');
        debugPrint('⚠️ Using mock mode instead');
        _isModelLoaded = false;
      } catch (e) {
        debugPrint('❌ Failed to load TFLite model: $e');
        debugPrint('⚠️ Falling back to mock mode');
        _isModelLoaded = false;
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize TFLite service: $e');
      _isModelLoaded = false;
    }
  }

  Future<Map<String, dynamic>> predict(File image) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    // Nếu model không load được, fallback về mock
    if (!_isModelLoaded || _interpreter == null) {
      return _mockPredict(image);
    }

    try {
      // Preprocess image
      final inputImage = await _preprocessImage(image);
      if (inputImage == null) {
        return _mockPredict(image);
      }

      // TFLite inference - Tạm thời disable
      // final inputList = <List<List<List<double>>>>[
      //   List.generate(224, (y) => List.generate(224, (x) {
      //     final idx = (y * 224 + x) * 3;
      //     return [inputImage[idx], inputImage[idx + 1], inputImage[idx + 2]];
      //   }))
      // ];
      // 
      // final outputShape = _interpreter!.getOutputTensor(0).shape;
      // final output = List.filled(
      //   outputShape.reduce((a, b) => a * b),
      //   0.0,
      // ).reshapeTFLite(outputShape);
      // 
      // _interpreter!.run(inputList, output);
      // final predictions = output[0] as List;
      
      // Fallback về mock
      return _mockPredict(image);
    } catch (e) {
      debugPrint('❌ Prediction error: $e');
      return _mockPredict(image);
    }
  }

  Future<List<dynamic>> predictMultiple(File image, {int numResults = 3}) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    // Nếu model không load được, fallback về mock
    if (!_isModelLoaded || _interpreter == null) {
      return _mockPredictMultiple(image, numResults);
    }

    try {
      // Preprocess image
      final inputImage = await _preprocessImage(image);
      if (inputImage == null) {
        return _mockPredictMultiple(image, numResults);
      }

      // TFLite inference - Tạm thời disable
      // final inputList = <List<List<List<double>>>>[
      //   List.generate(224, (y) => List.generate(224, (x) {
      //     final idx = (y * 224 + x) * 3;
      //     return [inputImage[idx], inputImage[idx + 1], inputImage[idx + 2]];
      //   }))
      // ];
      // 
      // final outputShape = _interpreter!.getOutputTensor(0).shape;
      // final output = List.filled(
      //   outputShape.reduce((a, b) => a * b),
      //   0.0,
      // ).reshapeTFLite(outputShape);
      // 
      // _interpreter!.run(inputList, output);
      // final predictions = output[0] as List;
      
      // Fallback về mock
      return _mockPredictMultiple(image, numResults);
    } catch (e) {
      debugPrint('❌ Multiple prediction error: $e');
      return _mockPredictMultiple(image, numResults);
    }
  }

  Future<Float32List?> _preprocessImage(File image) async {
    try {
      // Đọc ảnh
      final imageBytes = await image.readAsBytes();
      final imageData = img.decodeImage(imageBytes);
      if (imageData == null) return null;

      // Resize về 224x224 (hoặc kích thước model yêu cầu)
      final resized = img.copyResize(imageData, width: 224, height: 224);

      // Convert sang RGB và normalize về [0, 1]
      final input = Float32List(224 * 224 * 3);
      int index = 0;

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          input[index++] = (pixel.r / 255.0);
          input[index++] = (pixel.g / 255.0);
          input[index++] = (pixel.b / 255.0);
        }
      }

      // TFLite cần input dạng List 4D: [1, 224, 224, 3]
      // Nhưng method này trả về Float32List, nên ta cần reshape thành nested list
      // Tạm thời return input trực tiếp (sẽ xử lý reshape ở nơi gọi)
      return input;
    } catch (e) {
      debugPrint('❌ Image preprocessing error: $e');
      return null;
    }
  }

  double _estimateCalories(String foodLabel) {
    // Ước tính calo dựa trên database
    // Giả sử mỗi phần ăn khoảng 200-300g
    final baseCalories = _calorieDatabase[foodLabel] ?? 200.0;
    final portionWeight = 250.0; // gram
    return (baseCalories * portionWeight / 100.0).roundToDouble();
  }

  // Mock methods (fallback)
  Map<String, dynamic> _mockPredict(File image) {
    final hash = image.path.hashCode.abs();
    final index = hash % _labels.length;
    final label = _labels[index];
    final confidence = 0.7 + (hash % 300) / 1000.0;

    return {
      'label': label,
      'confidence': confidence,
      'index': index,
      'calories': _estimateCalories(label),
    };
  }

  List<dynamic> _mockPredictMultiple(File image, int numResults) {
    final hash = image.path.hashCode.abs();
    final baseIndex = hash % _labels.length;
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < numResults && i < _labels.length; i++) {
      final index = (baseIndex + i) % _labels.length;
      final confidence = 0.9 - (i * 0.3);
      if (confidence > 0.1) {
        results.add({
          'label': _labels[index],
          'confidence': confidence,
          'index': index,
          'calories': _estimateCalories(_labels[index]),
        });
      }
    }

    return results;
  }

  Future<void> closeModel() async {
    // _interpreter?.close();  // Tạm thời comment
    _interpreter = null;
    _isModelLoaded = false;
    debugPrint('✅ TFLite service closed');
  }

  List<String> get availableLabels => _labels;
  bool get isModelLoaded => _isModelLoaded;
}

// Extension để reshape list (sử dụng tên khác để tránh conflict)
extension ListReshapeTFLite on List {
  List reshapeTFLite(List<int> shape) {
    if (shape.length == 1) return this;
    final result = <dynamic>[];
    final chunkSize = shape.sublist(1).reduce((a, b) => a * b);
    for (int i = 0; i < length; i += chunkSize) {
      result.add(sublist(i, i + chunkSize).reshapeTFLite(shape.sublist(1)));
    }
    return result;
  }
}

