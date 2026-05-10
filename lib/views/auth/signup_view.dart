import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/signup_viewmodel.dart';
import '../../models/user_profile_model.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpViewModel(),
      child: const _SignUpViewContent(),
    );
  }
}

class _SignUpViewContent extends StatefulWidget {
  const _SignUpViewContent();

  @override
  State<_SignUpViewContent> createState() => _SignUpViewContentState();
}

class _SignUpViewContentState extends State<_SignUpViewContent> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpViewModel>();
    const accent = Color(0xFF4F8AF4);
    const deepAccent = Color(0xFF1E3C72);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, accent, deepAccent),
                _buildStepIndicator(context, viewModel, accent),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: _buildStepContent(context, viewModel, accent),
                    ),
                  ),
                ),
                _buildNavigationButtons(context, viewModel, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7EEFF),
            Color(0xFFF9FBFF),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent, Color deepAccent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
            child: Icon(Icons.person_add_rounded, color: accent, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create Account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in your details to get started',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
      BuildContext context, SignUpViewModel viewModel, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == viewModel.currentStep;
          final isCompleted = index < viewModel.currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? accent
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(
      BuildContext context, SignUpViewModel viewModel, Color accent) {
    switch (viewModel.currentStep) {
      case 0:
        return _buildStep1(context, viewModel, accent);
      case 1:
        return _buildStep2(context, viewModel, accent);
      case 2:
        return _buildStep3(context, viewModel, accent);
      case 3:
        return _buildStep4(context, viewModel, accent);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1(
      BuildContext context, SignUpViewModel viewModel, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal & Company Details', accent),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'User Name *',
          value: viewModel.profile.userName,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(userName: v),
          ),
          icon: Icons.person_outline_rounded,
          fieldKey: 'step0_userName',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'User name is required';
            }
            if (value.trim().length < 2) {
              return 'User name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Company Name *',
          value: viewModel.profile.companyName,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(companyName: v),
          ),
          icon: Icons.business_outlined,
          fieldKey: 'step0_companyName',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Company name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Company Address *',
          value: viewModel.profile.companyAddress,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(companyAddress: v),
          ),
          icon: Icons.location_on_outlined,
          maxLines: 3,
          fieldKey: 'step0_companyAddress',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Company address is required';
            }
            if (value.trim().length < 10) {
              return 'Please enter a complete address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Mobile Number *',
          value: viewModel.profile.mobileNumber,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(mobileNumber: v),
          ),
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          fieldKey: 'step0_mobileNumber',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Mobile number is required';
            }
            final phoneRegex = RegExp(r'^[0-9]{10}$');
            if (!phoneRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s-]'), ''))) {
              return 'Please enter a valid 10-digit mobile number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Email *',
          value: viewModel.profile.email,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(email: v),
          ),
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          fieldKey: 'step0_email',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            );
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2(
      BuildContext context, SignUpViewModel viewModel, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tax & Registration Details', accent),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'GST No *',
          value: viewModel.profile.gstNo,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(gstNo: v.toUpperCase()),
          ),
          icon: Icons.receipt_long_outlined,
          fieldKey: 'step1_gstNo',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'GST No is required';
            }
            final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
            if (!gstRegex.hasMatch(value.trim().toUpperCase())) {
              return 'Please enter a valid GST number (15 characters)';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'PAN No *',
          value: viewModel.profile.panNo,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(panNo: v.toUpperCase()),
          ),
          icon: Icons.badge_outlined,
          fieldKey: 'step1_panNo',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'PAN No is required';
            }
            final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
            if (!panRegex.hasMatch(value.trim().toUpperCase())) {
              return 'Please enter a valid PAN number (e.g., ABCDE1234F)';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'CST No',
          value: viewModel.profile.cstNo ?? '',
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(cstNo: v.isEmpty ? null : v),
          ),
          icon: Icons.description_outlined,
          fieldKey: 'step1_cstNo',
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'VAT No',
          value: viewModel.profile.vatNo ?? '',
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(vatNo: v.isEmpty ? null : v),
          ),
          icon: Icons.description_outlined,
          fieldKey: 'step1_vatNo',
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'IEC No',
          value: viewModel.profile.iecNo ?? '',
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(iecNo: v.isEmpty ? null : v),
          ),
          icon: Icons.description_outlined,
          fieldKey: 'step1_iecNo',
        ),
      ],
    );
  }

  Widget _buildStep3(
      BuildContext context, SignUpViewModel viewModel, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bank Details', accent),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Bank Name *',
          value: viewModel.profile.bankName,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(bankName: v),
          ),
          icon: Icons.account_balance_outlined,
          fieldKey: 'step2_bankName',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bank name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Branch *',
          value: viewModel.profile.branch,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(branch: v),
          ),
          icon: Icons.location_city_outlined,
          fieldKey: 'step2_branch',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Branch is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Account No *',
          value: viewModel.profile.accountNo,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(accountNo: v),
          ),
          icon: Icons.account_box_outlined,
          keyboardType: TextInputType.number,
          fieldKey: 'step2_accountNo',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Account number is required';
            }
            if (value.trim().length < 9) {
              return 'Account number must be at least 9 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'IFSC Code *',
          value: viewModel.profile.ifscCode,
          onChanged: (v) => viewModel.updateProfile(
            viewModel.profile.copyWith(ifscCode: v.toUpperCase()),
          ),
          icon: Icons.qr_code_outlined,
          fieldKey: 'step2_ifscCode',
          isRequired: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'IFSC code is required';
            }
            final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
            if (!ifscRegex.hasMatch(value.trim().toUpperCase())) {
              return 'Please enter a valid IFSC code (e.g., ABCD0123456)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep4(
      BuildContext context, SignUpViewModel viewModel, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Create Password', accent),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'Password *',
          value: viewModel.password,
          onChanged: viewModel.updatePassword,
          icon: Icons.lock_outline_rounded,
          fieldKey: 'step3_password',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildPasswordField(
          label: 'Confirm Password *',
          value: viewModel.confirmPassword,
          onChanged: viewModel.updateConfirmPassword,
          icon: Icons.lock_outline_rounded,
          fieldKey: 'step3_confirmPassword',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != viewModel.password) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (viewModel.password.isNotEmpty && viewModel.password.length < 6)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Password must be at least 6 characters',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (viewModel.confirmPassword.isNotEmpty &&
            viewModel.password != viewModel.confirmPassword)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Passwords do not match',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.12),
          ),
          child: Icon(Icons.info_outline, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? fieldKey,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    const accent = Color(0xFF4F8AF4);
    const surfaceTint = Color(0xFFF5F7FB);

    return TextFormField(
      key: fieldKey != null ? Key(fieldKey) : null,
      initialValue: value,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accent),
        filled: true,
        fillColor: surfaceTint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withOpacity(0.9), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
    String? fieldKey,
    String? Function(String?)? validator,
  }) {
    const accent = Color(0xFF4F8AF4);
    const surfaceTint = Color(0xFFF5F7FB);
    bool isObscured = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          key: fieldKey != null ? Key(fieldKey) : null,
          initialValue: value,
          obscureText: isObscured,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: accent),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: accent,
              ),
              onPressed: () => setState(() => isObscured = !isObscured),
            ),
            filled: true,
            fillColor: surfaceTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent.withOpacity(0.9), width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons(
      BuildContext context, SignUpViewModel viewModel, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (viewModel.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (viewModel.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => viewModel.previousStep(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: accent),
                      ),
                      child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (viewModel.currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: viewModel.currentStep == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () async {
                            if (viewModel.currentStep < 3) {
                              // Validate current step before proceeding
                              if (_formKey.currentState!.validate()) {
                                viewModel.nextStep();
                              }
                            } else {
                              // Validate final step before sign-up
                              if (_formKey.currentState!.validate()) {
                                final success = await viewModel.signUp();
                                if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Account created successfully!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                // Navigate to the root route and clear the entire
                                // back-stack (Onboarding, WelcomeView, SignUpView).
                                // Using pushNamedAndRemoveUntil avoids revealing
                                // the loading dashboard skeleton.
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home',
                                  (route) => false,
                                );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: accent.withOpacity(0.4),
                    ),
                    child: viewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            viewModel.currentStep < 3 ? 'Next' : 'Sign Up',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

