import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  static const int _lastStep = 4;

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

  bool _accountCreated = false;
  bool _emailVerified = false;
  bool _sendingVerification = false;
  bool _checkingVerification = false;

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfileModel get profile => _profile;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  bool get accountCreated => _accountCreated;
  bool get emailVerified => _emailVerified;
  bool get sendingVerification => _sendingVerification;
  bool get checkingVerification => _checkingVerification;
  int get totalSteps => _lastStep + 1;

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
      case 4:
        return _emailVerified;
      default:
        return false;
    }
  }

  void nextStep() {
    if (canProceedToNextStep() && _currentStep < _lastStep) {
      _currentStep++;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void previousStep() {
    // Once the account exists (step 4), going back is not allowed —
    // the auth user is real and the form data has been locked in.
    if (_accountCreated) return;
    if (_currentStep > 0) {
      _currentStep--;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= _lastStep) {
      _currentStep = step;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> createAccountAndSendVerification() async {
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

      if (userCredential?.user == null) {
        _isLoading = false;
        _errorMessage = 'Failed to create account';
        notifyListeners();
        return false;
      }

      await _authService.sendEmailVerification();

      _accountCreated = true;
      _currentStep = 4;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    if (_sendingVerification) return false;
    _sendingVerification = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.sendEmailVerification();
      _sendingVerification = false;
      notifyListeners();
      return true;
    } catch (e) {
      _sendingVerification = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkEmailVerifiedAndFinalize() async {
    if (_checkingVerification) return false;
    _checkingVerification = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final verified = await _authService.reloadAndCheckEmailVerified();
      if (!verified) {
        _checkingVerification = false;
        _errorMessage =
            'Email not verified yet. Please click the link in your inbox, then try again.';
        notifyListeners();
        return false;
      }

      final user = _authService.currentUser;
      if (user == null) {
        _checkingVerification = false;
        _errorMessage = 'Session expired. Please sign in again.';
        notifyListeners();
        return false;
      }

      await _userService.createUserProfile(
        uid: user.uid,
        profile: _profile,
      );

      _emailVerified = true;
      _checkingVerification = false;
      notifyListeners();
      return true;
    } catch (e) {
      _checkingVerification = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelPendingVerification() async {
    try {
      await _authService.deleteCurrentUser();
    } catch (_) {
      // If delete fails (e.g. requires recent login), fall through to sign-out.
    }
    try {
      await _authService.signOut();
    } catch (_) {}
    _accountCreated = false;
    _emailVerified = false;
    _currentStep = 3;
    _errorMessage = null;
    notifyListeners();
  }
}
