import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_translations.dart';
import '../../services/localization_service.dart';
import '../onboarding/onboarding_view.dart';
import '../auth/auth_wrapper.dart';


class LanguageSelectionView extends StatefulWidget {
  final bool isFromDrawer;
  
  const LanguageSelectionView({super.key, this.isFromDrawer = false});

  @override
  State<LanguageSelectionView> createState() => _LanguageSelectionViewState();
}

class _LanguageSelectionViewState extends State<LanguageSelectionView> {
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLang = LocalizationService.instance.currentLanguage;
  }

  void _onContinue() async {
    final locService = LocalizationService.instance;
    
    if (!widget.isFromDrawer) {
      await locService.setLanguage(_selectedLang, notify: false);
      await locService.markSelectionSeen();
      if (!mounted) return;
      // Navigate to onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingView()),
      );
    } else {
      await locService.setLanguage(_selectedLang, notify: true);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We don't watch the provider here directly so it doesn'.trt rebuild instantly and cause jumpiness,
    // we use our local state `_selectedLang`.
    final accent = const Color(0xFF4F8AF4);
    final deepAccent = const Color(0xFF1E3C72);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackdrop(accent, deepAccent),
          SafeArea(
            child: Column(
              children: [
                if (widget.isFromDrawer)
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.15),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.language_rounded,
                            size: 60,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Select Language'.tr,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: deepAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your preferred language'.tr,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 48),
                        _buildLangCard('English'.tr, 'en', 'English'.tr),
                        const SizedBox(height: 16),
                        _buildLangCard('Hindi'.tr, 'hi', 'हिंदी'),
                        const SizedBox(height: 16),
                        _buildLangCard('Gujarati'.tr, 'gu', 'ગુજરાતી'),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Continue'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangCard(String title, String langCode, String subtitle) {
    final isSelected = _selectedLang == langCode;
    final accent = const Color(0xFF4F8AF4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? accent.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accent : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _selectedLang = langCode;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? accent : const Color(0xFFF5F7FB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      subtitle[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF1E3C72) : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: accent,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackdrop(Color accent, Color deepAccent) {
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
            top: -100,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: -90,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: deepAccent.withOpacity(0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
