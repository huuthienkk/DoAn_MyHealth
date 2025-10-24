// firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/health_model.dart';
import '../models/mood_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMoodData(String uid, MoodData data) async {
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mood')
        .doc(data.date.toIso8601String());
    await doc.set(data.toMap());
  }

  Future<List<MoodData>> getMoodData(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mood')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => MoodData.fromMap(doc.data())).toList();
  }

  // hàm addHealthData
  Future<void> addHealthData(String uid, HealthData data) async {
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('health')
        .doc(data.date.toIso8601String());
    await doc.set(data.toMap());
  }

  Future<List<HealthData>> getHealthData(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('health')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => HealthData.fromMap(doc.data())).toList();
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return UserModel(uid: user.uid, email: email, name: name);
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (data != null && data.containsKey('uid') && data.containsKey('email')) {
      return UserModel.fromMap(data);
    } else {
      // Nếu Firestore chưa có user, tạo bản cơ bản
      final basicUser = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        name: user.displayName,
      );
      await _firestore.collection('users').doc(user.uid).set(basicUser.toMap());
      return basicUser;
    }
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async => await _auth.signOut();

  User? getCurrentUser() => _auth.currentUser;
}
