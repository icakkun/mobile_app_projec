import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../services/cloudinary_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingProfile = false;
  String? _profilePhotoUrl;

  // ✅ Matching Dashboard theme colors
  static const Color kBgTop = Color(0xFF0A1220);
  static const Color kBgBottom = Color(0xFF070D18);
  static const Color kCard = Color(0xFF0E1B2E);
  static const Color kCard2 = Color(0xFF101F36);
  static const Color kBorder = Color(0xFF1E2C44);
  static const Color kText = Color(0xFFEAF0F7);
  static const Color kMuted = Color(0xFF9AA7B4);

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  void _loadProfilePhoto() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.photoURL != null) {
      setState(() => _profilePhotoUrl = user!.photoURL);
    }
  }

  // ============================================
  // PROFILE PICTURE METHODS
  // ============================================

  Future<void> _changeProfilePicture() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                color: AppTheme.accentMint,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              _buildMenuItem(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                color: const Color(0xFF4DA3FF),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_profilePhotoUrl != null)
                _buildMenuItem(
                  icon: Icons.delete,
                  title: 'Remove Photo',
                  color: AppTheme.errorColor,
                  onTap: () => Navigator.pop(context, null),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source == null && _profilePhotoUrl != null) {
      await _removeProfilePicture();
    } else if (source != null) {
      await _uploadProfilePicture(source);
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: title.contains('Remove') ? AppTheme.errorColor : kText,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _uploadProfilePicture(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUpdatingProfile = true);

      final imageUrl = await CloudinaryService.uploadImage(image);

      if (imageUrl != null) {
        final user = FirebaseAuth.instance.currentUser;
        await user?.updatePhotoURL(imageUrl);
        await user?.reload();

        setState(() {
          _profilePhotoUrl = imageUrl;
          _isUpdatingProfile = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated!'),
              backgroundColor: AppTheme.accentMint,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      setState(() => _isUpdatingProfile = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      setState(() => _isUpdatingProfile = true);

      final user = FirebaseAuth.instance.currentUser;
      await user?.updatePhotoURL(null);
      await user?.reload();

      setState(() {
        _profilePhotoUrl = null;
        _isUpdatingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture removed'),
            backgroundColor: AppTheme.accentMint,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdatingProfile = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing photo: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ============================================
  // DISPLAY NAME METHODS
  // ============================================

  Future<void> _editDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kBorder, width: 1),
        ),
        title: const Text(
          'Edit Display Name',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
            labelStyle: TextStyle(color: kMuted),
            hintStyle: TextStyle(color: kMuted.withOpacity(0.6)),
            filled: true,
            fillColor: kBgBottom.withOpacity(0.6),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.accentMint),
            ),
          ),
          style: const TextStyle(color: kText),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMint,
              foregroundColor: kBgBottom,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (newName != null && newName != user?.displayName) {
      try {
        await user?.updateDisplayName(newName);
        await user?.reload();

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Display name updated!'),
              backgroundColor: AppTheme.accentMint,
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
              content: Text('Error updating name: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  // ============================================
  // PASSWORD METHODS
  // ============================================

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kBorder, width: 1),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(color: kText, fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                controller: currentPasswordController,
                label: 'Current Password',
                icon: Icons.lock,
                obscure: true,
              ),
              const SizedBox(height: 14),
              _dialogField(
                controller: newPasswordController,
                label: 'New Password',
                icon: Icons.lock_outline,
                hint: 'Min 6 characters',
                obscure: true,
              ),
              const SizedBox(height: 14),
              _dialogField(
                controller: confirmPasswordController,
                label: 'Confirm New Password',
                icon: Icons.lock_outline,
                obscure: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (currentPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter current password')),
                );
                return;
              }
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('New password must be at least 6 characters')),
                );
                return;
              }
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMint,
              foregroundColor: kBgBottom,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email;
        if (email == null) throw Exception('No email found');

        final credential = EmailAuthProvider.credential(
          email: email,
          password: currentPasswordController.text,
        );

        await user?.reauthenticateWithCredential(credential);
        await user?.updatePassword(newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password changed successfully!'),
              backgroundColor: AppTheme.accentMint,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Error changing password';
        if (e.code == 'wrong-password')
          message = 'Current password is incorrect';
        if (e.code == 'weak-password') message = 'New password is too weak';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppTheme.errorColor,
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
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: kText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.accentMint),
        labelStyle: TextStyle(color: kMuted),
        hintStyle: TextStyle(color: kMuted.withOpacity(0.55)),
        filled: true,
        fillColor: kBgBottom.withOpacity(0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentMint),
        ),
      ),
    );
  }

  // ============================================
  // EMAIL VERIFICATION METHODS
  // ============================================

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppTheme.accentMint,
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
            content: Text('Error sending email: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ============================================
  // LOGOUT METHOD
  // ============================================

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kBorder, width: 1),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(color: kText, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final createdDate = user?.metadata.creationTime;

    return Scaffold(
      backgroundColor: kBgBottom,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgTop, kBgBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              // ============================================
              // PROFILE SECTION
              // ============================================
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Picture
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentMint.withOpacity(0.4),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentMint.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor:
                                AppTheme.accentMint.withOpacity(0.18),
                            backgroundImage: _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!)
                                : null,
                            child: _isUpdatingProfile
                                ? const SizedBox(
                                    height: 32,
                                    width: 32,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.accentMint,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : _profilePhotoUrl == null
                                    ? Text(
                                        user?.displayName
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            user?.email
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'U',
                                        style: const TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.accentMint,
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUpdatingProfile
                                ? null
                                : _changeProfilePicture,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentMint,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kCard,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentMint.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: kBgBottom,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().scale(delay: 100.ms),
                    const SizedBox(height: 20),

                    Text(
                      user?.displayName ?? 'Anonymous User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: kText,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.1),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user?.email ?? 'No email',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (user?.emailVerified == true) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: AppTheme.accentMint,
                          ),
                        ],
                      ],
                    ).animate().fadeIn(delay: 200.ms),

                    if (createdDate != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: kBgBottom.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: kMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Joined ${DateFormat('MMM yyyy').format(createdDate)}',
                              style: TextStyle(
                                color: kMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 250.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                    ],
                  ],
                ),
              ),

              // ============================================
              // PROFILE MANAGEMENT
              // ============================================
              _buildSectionHeader('PROFILE').animate().fadeIn(delay: 300.ms),
              _buildSectionCard(
                children: [
                  _buildTile(
                    icon: Icons.person,
                    iconColor: AppTheme.accentMint,
                    title: 'Edit Display Name',
                    subtitle: user?.displayName ?? 'Not set',
                    onTap: _editDisplayName,
                  ),
                  _tileDivider(),
                  _buildTile(
                    icon: Icons.lock,
                    iconColor: AppTheme.accentMint,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: _changePassword,
                  ),
                  if (user?.emailVerified == false) ...[
                    _tileDivider(),
                    _buildTile(
                      icon: Icons.mark_email_unread,
                      iconColor: AppTheme.warningColor,
                      title: 'Verify Email',
                      subtitle: 'Email not verified',
                      onTap: _sendVerificationEmail,
                    ),
                  ],
                ],
              ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),

              // ============================================
              // ACCOUNT SECTION
              // ============================================
              _buildSectionHeader('ACCOUNT').animate().fadeIn(delay: 400.ms),
              _buildSectionCard(
                children: [
                  _buildTile(
                    icon: Icons.logout,
                    iconColor: AppTheme.errorColor,
                    title: 'Log Out',
                    titleColor: AppTheme.errorColor,
                    onTap: () => _logout(context),
                  ),
                ],
              ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1),

              // ============================================
              // APP INFO
              // ============================================
              _buildSectionHeader('ABOUT').animate().fadeIn(delay: 500.ms),
              _buildSectionCard(
                children: [
                  _buildTile(
                    icon: Icons.info_outline,
                    iconColor: AppTheme.accentMint,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    onTap: null,
                  ),
                  _tileDivider(),
                  _buildTile(
                    icon: Icons.flight_takeoff,
                    iconColor: AppTheme.accentMint,
                    title: 'Trip Mint',
                    subtitle: 'Travel Budget Planner',
                    onTap: null,
                  ),
                ],
              ).animate().fadeIn(delay: 550.ms).slideX(begin: -0.1),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: kMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.22)),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? kText,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: kMuted,
                fontSize: 13,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: kMuted,
              size: 22,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _tileDivider() => Divider(
        height: 1,
        thickness: 1,
        color: kBorder,
        indent: 16,
        endIndent: 16,
      );
}
