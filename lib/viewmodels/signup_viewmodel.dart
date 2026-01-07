import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel _profile = UserProfileModel(
    userName: '',
    companyName: '',
    companyAddress: '',
    mobileNumber: '',
    email: '',
    gstNo: '',
    panNo: '',
    bankName: '',
    branch: '',
    accountNo: '',
    ifscCode: '',
  );

  String _password = '';
  String _confirmPassword = '';

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfileModel get profile => _profile;
  String get password => _password;
  String get confirmPassword => _confirmPassword;

  void updateProfile(UserProfileModel newProfile) {
    _profile = newProfile;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  bool canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _profile.userName.isNotEmpty &&
            _profile.companyName.isNotEmpty &&
            _profile.companyAddress.isNotEmpty &&
            _profile.mobileNumber.isNotEmpty &&
            _profile.email.isNotEmpty;
      case 1:
        return _profile.gstNo.isNotEmpty && _profile.panNo.isNotEmpty;
      case 2:
        return _profile.bankName.isNotEmpty &&
            _profile.branch.isNotEmpty &&
            _profile.accountNo.isNotEmpty &&
            _profile.ifscCode.isNotEmpty;
      case 3:
        return _password.length >= 6 && _password == _confirmPassword;
      default:
        return false;
    }
  }

  void nextStep() {
    if (canProceedToNextStep() && _currentStep < 3) {
      _currentStep++;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      _currentStep = step;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signUp() async {
    if (!canProceedToNextStep()) {
      _errorMessage = 'Please fill all required fields';
      notifyListeners();
      return false;
    }

    if (_password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    if (_password != _confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: _profile.email,
        password: _password,
      );

      if (userCredential?.user != null) {
        await _userService.createUserProfile(
          uid: userCredential!.user!.uid,
          profile: _profile,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Failed to create account';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

