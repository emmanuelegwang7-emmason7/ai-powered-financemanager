import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';

/// Settings Screen — satisfies M2 "Open one external app or phone service"
/// requirement by launching the device's native Email app and Browser.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states (stored locally; would normally persist with SharedPrefs)
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  bool _darkMode = true;
  bool _showBalance = true;

  /// Launches a URL. Shows a SnackBar on failure.
  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open: $urlString',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens the native Email app pre-filled with support details.
  Future<void> _launchEmailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@smartfinanceai.com',
      queryParameters: {
        'subject': 'SmartFinance AI - Support Request',
        'body':
            'Hello SmartFinance AI Support Team,\n\nI need help with:\n\n[Describe your issue here]\n\nApp version: 1.0.0',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found on this device.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: AppTextStyles.heading),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Section: Preferences ────────────────────────────────────
              _sectionHeader('Preferences'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                children: [
                  _buildToggleTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Alerts for spending limits',
                    value: _notificationsEnabled,
                    onChanged: (v) =>
                        setState(() => _notificationsEnabled = v),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.fingerprint,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face ID',
                    value: _biometricsEnabled,
                    onChanged: (v) =>
                        setState(() => _biometricsEnabled = v),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Always on for AMOLED savings',
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    icon: Icons.visibility_outlined,
                    title: 'Show Balance',
                    subtitle: 'Display balance on dashboard',
                    value: _showBalance,
                    onChanged: (v) => setState(() => _showBalance = v),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section: Support & Legal ────────────────────────────────
              _sectionHeader('Support & Legal'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                children: [
                  // ★ KEY: Opens native Email app (External App / Intent requirement)
                  _buildActionTile(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.successGreen,
                    title: 'Contact Support',
                    subtitle: 'Opens your Email app',
                    onTap: _launchEmailSupport,
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                  _buildDivider(),
                  // ★ KEY: Opens Browser (second external app trigger)
                  _buildActionTile(
                    icon: Icons.help_outline,
                    iconColor: AppColors.primary,
                    title: 'Help Centre',
                    subtitle: 'Opens in your browser',
                    onTap: () => _launchURL('https://flutter.dev'),
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.white54,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    onTap: () => _launchURL(
                      'https://www.termsfeed.com/live/privacy-policy',
                    ),
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    icon: Icons.description_outlined,
                    iconColor: Colors.white54,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    onTap: () => _launchURL(
                      'https://www.termsfeed.com/live/terms-of-service',
                    ),
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section: About ──────────────────────────────────────────
              _sectionHeader('About'),
              const SizedBox(height: 8),
              _buildSettingsCard(
                children: [
                  _buildActionTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.white54,
                    title: 'App Version',
                    subtitle: 'SmartFinance AI v1.0.0',
                    onTap: null,
                    trailing: const SizedBox.shrink(),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    icon: Icons.star_outline,
                    iconColor: Colors.amber,
                    title: 'Rate the App',
                    subtitle: 'Opens app store',
                    onTap: () => _launchURL('https://play.google.com/store'),
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Footer ──────────────────────────────────────────────────
              Center(
                child: Text(
                  'SmartFinance AI © 2026',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.body.copyWith(
        fontSize: 11,
        color: Colors.white38,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: Colors.white60, size: 22),
      title: Text(title, style: AppTextStyles.body.copyWith(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.body.copyWith(
          fontSize: 12,
          color: Colors.white38,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: AppTextStyles.body.copyWith(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.body.copyWith(
          fontSize: 12,
          color: Colors.white38,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.06),
      indent: 54,
    );
  }
}
