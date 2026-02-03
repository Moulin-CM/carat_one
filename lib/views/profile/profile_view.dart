import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../models/user_profile_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(),
      child: const _ProfileViewContent(),
    );
  }
}

class _ProfileViewContent extends StatefulWidget {
  const _ProfileViewContent();

  @override
  State<_ProfileViewContent> createState() => _ProfileViewContentState();
}

class _ProfileViewContentState extends State<_ProfileViewContent> {
  final _formKey = GlobalKey<FormState>();
  final accent = const Color(0xFF4F8AF4);
  final deepAccent = const Color(0xFF1E3C72);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
              child: Icon(Icons.person_outline_rounded, color: accent),
            ),
            const SizedBox(width: 10),
            const Text('Profile'),
          ],
        ),
        actions: [
          if (!viewModel.isEditing && viewModel.profile != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => viewModel.startEditing(),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.profile == null
                    ? _buildErrorState(viewModel)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileHeader(viewModel),
                              const SizedBox(height: 24),
                              if (viewModel.isEditing)
                                _buildEditForm(viewModel)
                              else
                                _buildViewMode(viewModel),
                            ],
                          ),
                        ),
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
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: deepAccent.withOpacity(0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProfileViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Failed to load profile',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => viewModel.loadProfile(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileViewModel viewModel) {
    final profile = viewModel.profile!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.companyName,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              profile.email,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode(ProfileViewModel viewModel) {
    final profile = viewModel.profile!;
    return Column(
      children: [
        _buildInfoSection(
          'Personal Information',
          Icons.person_outline_rounded,
          [
            _buildInfoRow('User Name', profile.userName),
            _buildInfoRow('Mobile Number', profile.mobileNumber),
            _buildInfoRow('Email', profile.email),
          ],
        ),
        const SizedBox(height: 18),
        _buildInfoSection(
          'Company Details',
          Icons.business_outlined,
          [
            _buildInfoRow('Company Name', profile.companyName),
            _buildInfoRow('Company Address', profile.companyAddress),
          ],
        ),
        const SizedBox(height: 18),
        _buildInfoSection(
          'Tax & Registration',
          Icons.receipt_long_outlined,
          [
            _buildInfoRow('GST No', profile.gstNo),
            _buildInfoRow('PAN No', profile.panNo),
            if (profile.cstNo != null && profile.cstNo!.isNotEmpty)
              _buildInfoRow('CST No', profile.cstNo!),
            if (profile.vatNo != null && profile.vatNo!.isNotEmpty)
              _buildInfoRow('VAT No', profile.vatNo!),
            if (profile.iecNo != null && profile.iecNo!.isNotEmpty)
              _buildInfoRow('IEC No', profile.iecNo!),
          ],
        ),
        const SizedBox(height: 18),
        _buildInfoSection(
          'Bank Details',
          Icons.account_balance_outlined,
          [
            _buildInfoRow('Bank Name', profile.bankName),
            _buildInfoRow('Branch', profile.branch),
            _buildInfoRow('Account No', profile.accountNo),
            _buildInfoRow('IFSC Code', profile.ifscCode),
          ],
        ),
        if (profile.createdAt != null) ...[
          const SizedBox(height: 18),
          _buildInfoSection(
            'Account Information',
            Icons.info_outline_rounded,
            [
              _buildInfoRow(
                'Member Since',
                DateFormat('dd MMM yyyy').format(profile.createdAt!),
              ),
              if (profile.updatedAt != null)
                _buildInfoRow(
                  'Last Updated',
                  DateFormat('dd MMM yyyy').format(profile.updatedAt!),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(ProfileViewModel viewModel) {
    final profile = viewModel.profile!;
    const surfaceTint = Color(0xFFF5F7FB);

    return Column(
      children: [
        if (viewModel.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Information', accent),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'User Name *',
                value: profile.userName,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(userName: v),
                ),
                icon: Icons.person_outline_rounded,
                surfaceTint: surfaceTint,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Mobile Number *',
                value: profile.mobileNumber,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(mobileNumber: v),
                ),
                icon: Icons.phone_outlined,
                surfaceTint: surfaceTint,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Company Details', accent),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Company Name *',
                value: profile.companyName,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(companyName: v),
                ),
                icon: Icons.business_outlined,
                surfaceTint: surfaceTint,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Company Address *',
                value: profile.companyAddress,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(companyAddress: v),
                ),
                icon: Icons.location_on_outlined,
                surfaceTint: surfaceTint,
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tax & Registration', accent),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'GST No *',
                value: profile.gstNo,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(gstNo: v.toUpperCase()),
                ),
                icon: Icons.receipt_long_outlined,
                surfaceTint: surfaceTint,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'PAN No *',
                value: profile.panNo,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(panNo: v.toUpperCase()),
                ),
                icon: Icons.badge_outlined,
                surfaceTint: surfaceTint,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'CST No',
                value: profile.cstNo ?? '',
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(cstNo: v.isEmpty ? null : v),
                ),
                icon: Icons.description_outlined,
                surfaceTint: surfaceTint,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'VAT No',
                value: profile.vatNo ?? '',
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(vatNo: v.isEmpty ? null : v),
                ),
                icon: Icons.description_outlined,
                surfaceTint: surfaceTint,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'IEC No',
                value: profile.iecNo ?? '',
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(iecNo: v.isEmpty ? null : v),
                ),
                icon: Icons.description_outlined,
                surfaceTint: surfaceTint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Bank Details', accent),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Bank Name *',
                value: profile.bankName,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(bankName: v),
                ),
                icon: Icons.account_balance_outlined,
                surfaceTint: surfaceTint,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Branch *',
                value: profile.branch,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(branch: v),
                ),
                icon: Icons.location_city_outlined,
                surfaceTint: surfaceTint,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Account No *',
                value: profile.accountNo,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(accountNo: v),
                ),
                icon: Icons.account_box_outlined,
                surfaceTint: surfaceTint,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'IFSC Code *',
                value: profile.ifscCode,
                onChanged: (v) => viewModel.updateProfile(
                  profile.copyWith(ifscCode: v.toUpperCase()),
                ),
                icon: Icons.qr_code_outlined,
                surfaceTint: surfaceTint,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: viewModel.isSaving
                    ? null
                    : () => viewModel.cancelEditing(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: accent),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: viewModel.isSaving
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await viewModel.saveProfile();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
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
                child: viewModel.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
    required Color surfaceTint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: value,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: accent, size: 22),
        filled: true,
        fillColor: surfaceTint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

