import 'package:firebase_database/firebase_database.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import '../models/user_profile_model.dart';


class UserService {
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref('users'.tr);

  Future<void> createUserProfile({
    required String uid,
    required UserProfileModel profile,
  }) async {
    try {
      final profileData = profile.copyWith(
        uid: uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toJson();

      await _usersRef.child(uid).set(profileData);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required UserProfileModel profile,
  }) async {
    try {
      final profileData = profile.copyWith(
        uid: uid,
        updatedAt: DateTime.now(),
      ).toJson();

      await _usersRef.child(uid).update(profileData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();

      if (snapshot.value == null) {
        return null;
      }

      final data = Map<String, dynamic>.from(
        snapshot.value as Map<Object?, Object?>,
      );

      return UserProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> deleteUserProfile(String uid) async {
    try {
      await _usersRef.child(uid).remove();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }
}

