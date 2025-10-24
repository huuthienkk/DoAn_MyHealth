class UserModel {
  final String uid;
  final String email;
  final String? name;

  UserModel({required this.uid, required this.email, this.name});

  factory UserModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) throw ArgumentError("Null map");
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'name': name};
  }
}
