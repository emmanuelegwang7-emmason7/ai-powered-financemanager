import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';

/// Profile Screen — allows the user to view their info and pick a photo
/// from the device gallery to use as their profile picture.
class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _pickedImage;          // null = no photo picked yet, show initials
  bool _isPickingImage = false; // prevent double-taps

  // ── Derived display values ──────────────────────────────────────────────
  late String _displayName;
  late String _initials;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName.isNotEmpty
        ? widget.userName
        : widget.userEmail.split('@')[0].replaceAll('.', ' ');

    _initials = _displayName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  // ── Pick image from gallery ─────────────────────────────────────────────
  Future<void> _pickImageFromGallery() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,   // compress slightly to keep file size reasonable
        maxWidth: 600,
        maxHeight: 600,
      );

      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Profile photo updated!',
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open gallery. Please allow photo access in Settings.',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // ── Remove photo, revert to initials ───────────────────────────────────
  void _removePhoto() {
    setState(() => _pickedImage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile photo removed.',
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Show bottom sheet with photo options ────────────────────────────────
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            color: const Color(0xFF1E293B),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text('Profile Photo', style: AppTextStyles.subHeading),
                const SizedBox(height: 20),

                // Choose from gallery
                _photoOptionTile(
                  icon: Icons.photo_library_outlined,
                  iconColor: AppColors.primary,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),

                // Remove photo (only if one is set)
                if (_pickedImage != null) ...[
                  const SizedBox(height: 4),
                  _photoOptionTile(
                    icon: Icons.delete_outline,
                    iconColor: AppColors.errorRed,
                    label: 'Remove Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
                ],

                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.body.copyWith(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoOptionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(label, style: AppTextStyles.body.copyWith(color: Colors.white)),
      onTap: onTap,
    );
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
        title: Text('My Profile', style: AppTextStyles.heading),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Avatar with camera overlay ───────────────────────────
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Avatar circle
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.6),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _pickedImage != null
                              // Show the picked gallery photo
                              ? Image.file(
                                  _pickedImage!,
                                  fit: BoxFit.cover,
                                  width: 108,
                                  height: 108,
                                )
                              // Show initials fallback
                              : Container(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Text(
                                      _initials.isEmpty ? '?' : _initials,
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      // Camera icon badge (tap indicator)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bgGradientStart,
                            width: 2,
                          ),
                        ),
                        child: _isPickingImage
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tap hint
                Text(
                  'Tap photo to change',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Name & email ─────────────────────────────────────────
                Text(
                  _capitalise(_displayName),
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userEmail,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── Info card ─────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          _profileRow(
                            Icons.person_outline,
                            'Full Name',
                            _capitalise(_displayName),
                          ),
                          const Divider(color: Colors.white12),
                          _profileRow(
                            Icons.email_outlined,
                            'Email Address',
                            widget.userEmail,
                          ),
                          const Divider(color: Colors.white12),
                          _profileRow(
                            Icons.verified_user_outlined,
                            'Account Type',
                            'Free Plan',
                          ),
                          const Divider(color: Colors.white12),
                          _profileRow(
                            Icons.calendar_today_outlined,
                            'Member Since',
                            'October 2026',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Stats row ─────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        '4',
                        'Transactions',
                        Icons.receipt_long_outlined,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        '0',
                        'Savings Goals',
                        Icons.savings_outlined,
                        AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        '1',
                        'AI Chats',
                        Icons.smart_toy_outlined,
                        AppColors.bgGradientEnd,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Change photo button ───────────────────────────────────
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                  label: Text(
                    _pickedImage == null ? 'Add Profile Photo' : 'Change Photo',
                    style: AppTextStyles.button,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showPhotoOptions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _capitalise(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
