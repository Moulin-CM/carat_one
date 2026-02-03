import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  UserProfileModel? _profile;

  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  UserProfileModel? get profile => _profile;

  Future<void> loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _userService.getUserProfile(user.uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void startEditing() {
    _isEditing = true;
    _errorMessage = null;
    notifyListeners();
  }

  void cancelEditing() {
    _isEditing = false;
    _errorMessage = null;
    // Reload original profile
    loadProfile();
  }

  void updateProfile(UserProfileModel newProfile) {
    _profile = newProfile;
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    if (_profile == null) {
      _errorMessage = 'No profile to save';
      notifyListeners();
      return false;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.updateUserProfile(
        uid: user.uid,
        profile: _profile!,
      );
      _isSaving = false;
      _isEditing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

