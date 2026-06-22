import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../constants/app_translations.dart';

/// Modern UI surface for the Profile screen.
///
/// Same `ProfileViewModel`, same load / edit / save flows, same field
/// validators and copy-with updates. Only the visual layer is restyled
/// — dark navy backdrop, gradient header card, glass sections, modern
/// floating save button.
class ModernProfileContent extends StatefulWidget {
  const ModernProfileContent({super.key});

  @override
  State<ModernProfileContent> createState() => _ModernProfileContentState();
}

class _ModernProfileContentState extends State<ModernProfileContent> {
  final _formKey = GlobalKey<FormState>();

  // Website tokens
  static const _bg0 = Color(0xFF07091C);
  static const _bg1 = Color(0xFF0C1230);
  static const _primary = Color(0xFF4F8AF4);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  static const _grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _accent, _violet],
    stops: [0.0, 0.5, 1.0],
  );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: _bg0,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, vm),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _accent))
                : vm.profile == null
                    ? _buildErrorState(vm)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileHeader(vm),
                              const SizedBox(height: 18),
                              if (vm.isEditing)
                                _buildEditForm(vm)
                              else
                                _buildViewMode(vm),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton:
          vm.profile != null && vm.isEditing ? _buildSaveBar(context, vm) : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ProfileViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
        ).createShader(rect),
        child: Text(
          'Profile'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      actions: [
        if (!vm.isEditing && vm.profile != null)
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Edit Profile'.tr,
            onPressed: () => vm.startEditing(),
          ),
      ],
    );
  }

  // ─────────────────────────────  BACKDROP  ───────────────────────────────

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bg1, _bg0],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _glow(280, _primary.withOpacity(0.25)),
          ),
          Positioned(
            top: 240,
            left: -100,
            child: _glow(240, _violet.withOpacity(0.18)),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  // ─────────────────────────────  ERROR STATE  ────────────────────────────

  Widget _buildErrorState(ProfileViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              vm.errorMessage ?? 'Failed to load profile'.tr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => vm.loadProfile(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Retry'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────  HEADER  ─────────────────────────────────

  Widget _buildProfileHeader(ProfileViewModel vm) {
    final profile = vm.profile!;
    final initials = _initials(profile.userName);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.userName.isEmpty ? '—' : profile.userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (profile.companyName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (profile.email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.30), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    profile.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────  VIEW MODE  ──────────────────────────────

  Widget _buildViewMode(ProfileViewModel vm) {
    final profile = vm.profile!;
    return Column(
      children: [
        _infoSection(
          title: 'Personal Information'.tr,
          icon: Icons.person_outline_rounded,
          gradient: const [_primary, _accent],
          rows: [
            _infoRow('User Name'.tr, profile.userName),
            _infoRow('Mobile Number'.tr, profile.mobileNumber),
            _infoRow('Email'.tr, profile.email),
          ],
        ),
        const SizedBox(height: 16),
        _infoSection(
          title: 'Company Details'.tr,
          icon: Icons.business_outlined,
          gradient: const [_accent, _violet],
          rows: [
            _infoRow('Company Name'.tr, profile.companyName),
            _infoRow('Company Address'.tr, profile.companyAddress),
          ],
        ),
        const SizedBox(height: 16),
        _infoSection(
          title: 'Tax & Registration'.tr,
          icon: Icons.receipt_long_outlined,
          gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          rows: [
            _infoRow('GST No'.tr, profile.gstNo),
            _infoRow('PAN No'.tr, profile.panNo),
            if (profile.cstNo != null && profile.cstNo!.isNotEmpty)
              _infoRow('CST No'.tr, profile.cstNo!),
            if (profile.vatNo != null && profile.vatNo!.isNotEmpty)
              _infoRow('VAT No'.tr, profile.vatNo!),
            if (profile.iecNo != null && profile.iecNo!.isNotEmpty)
              _infoRow('IEC No'.tr, profile.iecNo!),
          ],
        ),
        const SizedBox(height: 16),
        _infoSection(
          title: 'Bank Details'.tr,
          icon: Icons.account_balance_outlined,
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
          rows: [
            _infoRow('Bank Name'.tr, profile.bankName),
            _infoRow('Branch'.tr, profile.branch),
            _infoRow('Account No'.tr, profile.accountNo),
            _infoRow('IFSC Code'.tr, profile.ifscCode),
          ],
        ),
        if (profile.createdAt != null) ...[
          const SizedBox(height: 16),
          _infoSection(
            title: 'Account Information'.tr,
            icon: Icons.info_outline_rounded,
            gradient: const [Color(0xFF6366F1), _violet],
            rows: [
              _infoRow(
                'Member Since'.tr,
                DateFormat('dd MMM yyyy'.tr).format(profile.createdAt!),
              ),
              if (profile.updatedAt != null)
                _infoRow(
                  'Last Updated'.tr,
                  DateFormat('dd MMM yyyy'.tr).format(profile.updatedAt!),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _infoSection({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withOpacity(0.55),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: value.isEmpty
                  ? Colors.white.withOpacity(0.45)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  EDIT FORM  ──────────────────────────────

  Widget _buildEditForm(ProfileViewModel vm) {
    final profile = vm.profile!;
    return Column(
      children: [
        if (vm.errorMessage != null) ...[
          _errorBanner(vm.errorMessage!),
          const SizedBox(height: 12),
        ],
        _editSection(
          title: 'Personal Information'.tr,
          icon: Icons.person_outline_rounded,
          gradient: const [_primary, _accent],
          children: [
            _textField(
              label: '${'User Name'.tr} *',
              value: profile.userName,
              icon: Icons.person_outline_rounded,
              onChanged: (v) =>
                  vm.updateProfile(profile.copyWith(userName: v)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
            const SizedBox(height: 12),
            _textField(
              label: '${'Mobile Number'.tr} *',
              value: profile.mobileNumber,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              onChanged: (v) =>
                  vm.updateProfile(profile.copyWith(mobileNumber: v)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _editSection(
          title: 'Company Details'.tr,
          icon: Icons.business_outlined,
          gradient: const [_accent, _violet],
          children: [
            _textField(
              label: '${'Company Name'.tr} *',
              value: profile.companyName,
              icon: Icons.business_outlined,
              onChanged: (v) =>
                  vm.updateProfile(profile.copyWith(companyName: v)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
            const SizedBox(height: 12),
            _textField(
              label: '${'Company Address'.tr} *',
              value: profile.companyAddress,
              icon: Icons.location_on_outlined,
              maxLines: 3,
              onChanged: (v) =>
                  vm.updateProfile(profile.copyWith(companyAddress: v)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _editSection(
          title: 'Tax & Registration'.tr,
          icon: Icons.receipt_long_outlined,
          gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          children: [
            _textField(
              label: '${'GST No'.tr} *',
              value: profile.gstNo,
              icon: Icons.receipt_long_outlined,
              onChanged: (v) => vm.updateProfile(
                  profile.copyWith(gstNo: v.toUpperCase())),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
            const SizedBox(height: 12),
            _textField(
              label: '${'PAN No'.tr} *',
              value: profile.panNo,
              icon: Icons.badge_outlined,
              onChanged: (v) => vm.updateProfile(
                  profile.copyWith(panNo: v.toUpperCase())),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'CST No'.tr,
              value: profile.cstNo ?? '',
              icon: Icons.description_outlined,
              onChanged: (v) => vm.updateProfile(
                  profile.copyWith(cstNo: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'VAT No'.tr,
              value: profile.vatNo ?? '',
              icon: Icons.description_outlined,
              onChanged: (v) => vm.updateProfile(
                  profile.copyWith(vatNo: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'IEC No'.tr,
              value: profile.iecNo ?? '',
              icon: Icons.description_outlined,
              onChanged: (v) => vm.updateProfile(
                  profile.copyWith(iecNo: v.isEmpty ? null : v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _editSection(
          title: 'Bank Details'.tr,
          icon: Icons.account_balance_outlined,
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
          children: [
            _textField(
              label: '${'Bank Name'.tr} *',
              value: profile.bankName,
              icon: Icons.account_balance_outlined,
              onChanged: (v) =>
                  vm.updateProfile(profile.copyWith(bankName: v)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
            const SizedBox(height: 12),
            _textField(
              label: '${'Branch'.tr} *',
              value: profile.branch,
              icon: Icons.location_city_outlined,
              onChanged: (v) =>
                  vm.updateProfile(profile.copyWith(branch: v)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
            const SizedBox(height: 12),
            _textField(
              label: '${'Account No'.tr} *',
              value: profile.accountNo,
              icon: Icons.account_box_outlined,
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  vm.updateProfile(profile.copyWith(accountNo: v)),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
            const SizedBox(height: 12),
            _textField(
              label: '${'IFSC Code'.tr} *',
              value: profile.ifscCode,
              icon: Icons.qr_code_outlined,
              onChanged: (v) => vm.updateProfile(
                  profile.copyWith(ifscCode: v.toUpperCase())),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required'.tr : null,
            ),
          ],
        ),
        // Cancel button — Save is in the floating slot.
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: vm.isSaving ? null : () => vm.cancelEditing(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Center(
                  child: Text(
                    'Cancel'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFEF4444).withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFFCA5A5), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editSection({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
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

  // ─────────────────────────────  TEXT FIELD  ─────────────────────────────

  Widget _textField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: _accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: _accent,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 0),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        errorStyle: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────  FLOATING SAVE  ──────────────────────────

  Widget _buildSaveBar(BuildContext context, ProfileViewModel vm) {
    final pillWidth = MediaQuery.of(context).size.width - 32;
    final busy = vm.isSaving;
    return SizedBox(
      width: pillWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: busy
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    final success = await vm.saveProfile();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Profile updated successfully!'.tr),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: busy ? null : _grad,
              color: busy ? Colors.white.withOpacity(0.10) : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: busy
                  ? null
                  : [
                      BoxShadow(
                        color: _primary.withOpacity(0.45),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: _violet.withOpacity(0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  const Icon(Icons.save_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Save Changes'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
