import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.accentMint),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.accentMint),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profilePhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Remove Photo'),
                onTap: () => Navigator.pop(context, null),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null && _profilePhotoUrl != null) {
      await _removeProfilePicture();
    } else if (source != null) {
      await _uploadProfilePicture(source);
    }
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
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: AppTheme.accentMint,
              behavior: SnackBarBehavior.floating,
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
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: AppTheme.accentMint,
            behavior: SnackBarBehavior.floating,
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
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Edit Display Name',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            hintStyle:
                TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.textSecondary.withOpacity(0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.accentMint.withOpacity(0.7)),
            ),
          ),
          style: TextStyle(color: AppTheme.textPrimary),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMint,
              foregroundColor: AppTheme.background,
            ),
            child: const Text('Save'),
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
            const SnackBar(
              content: Text('Display name updated!'),
              backgroundColor: AppTheme.accentMint,
              behavior: SnackBarBehavior.floating,
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
        backgroundColor: AppTheme.cardBackground,
        title: Text('Change Password',
            style: TextStyle(color: AppTheme.textPrimary)),
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
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
              foregroundColor: AppTheme.background,
            ),
            child: const Text('Change Password'),
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
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: AppTheme.accentMint,
              behavior: SnackBarBehavior.floating,
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
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.accentMint),
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.55)),
        filled: true,
        fillColor: AppTheme.background.withOpacity(0.35),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.textSecondary.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentMint.withOpacity(0.7)),
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
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppTheme.accentMint,
            behavior: SnackBarBehavior.floating,
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
        backgroundColor: AppTheme.cardBackground,
        title: Text('Log Out', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
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
            ),
          );
        }
      }
    }
  }

  // ============================================
  // UI HELPERS
  // ============================================

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _tileDivider() => Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.textSecondary.withOpacity(0.10),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final createdDate = user?.metadata.creationTime;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // ============================================
          // PROFILE SECTION
          // ============================================
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
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
                          color: AppTheme.accentMint.withOpacity(0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentMint.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: AppTheme.accentMint.withOpacity(0.20),
                        backgroundImage: _profilePhotoUrl != null
                            ? NetworkImage(_profilePhotoUrl!)
                            : null,
                        child: _isUpdatingProfile
                            ? const SizedBox(
                                height: 28,
                                width: 28,
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
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.accentMint,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap:
                            _isUpdatingProfile ? null : _changeProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppTheme.accentMint,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.cardBackground,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: AppTheme.background,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Text(
                  user?.displayName ?? 'Anonymous User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user?.email ?? 'No email',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                    if (user?.emailVerified == true) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 16, color: AppTheme.accentMint),
                    ],
                  ],
                ),

                if (createdDate != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.background.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14,
                            color: AppTheme.textSecondary.withOpacity(0.9)),
                        const SizedBox(width: 6),
                        Text(
                          'Joined ${DateFormat('MMM yyyy').format(createdDate)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ============================================
          // PROFILE MANAGEMENT
          // ============================================
          _buildSectionHeader('PROFILE'),
          _sectionCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.accentMint),
                  title: Text('Edit Display Name',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text(user?.displayName ?? 'Not set',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  trailing: Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary.withOpacity(0.8)),
                  onTap: _editDisplayName,
                ),
                _tileDivider(),
                ListTile(
                  leading: const Icon(Icons.lock, color: AppTheme.accentMint),
                  title: Text('Change Password',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text('Update your password',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  trailing: Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary.withOpacity(0.8)),
                  onTap: _changePassword,
                ),
                if (user?.emailVerified == false) ...[
                  _tileDivider(),
                  ListTile(
                    leading: const Icon(Icons.mark_email_unread,
                        color: AppTheme.warningColor),
                    title: Text('Verify Email',
                        style: TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text('Email not verified',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    trailing: Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary.withOpacity(0.8)),
                    onTap: _sendVerificationEmail,
                  ),
                ],
              ],
            ),
          ),

          // ============================================
          // ACCOUNT SECTION
          // ============================================
          _buildSectionHeader('ACCOUNT'),
          _sectionCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text(
                'Log Out',
                style: TextStyle(
                    color: AppTheme.errorColor, fontWeight: FontWeight.w700),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: AppTheme.errorColor),
              onTap: () => _logout(context),
            ),
          ),

          // ============================================
          // APP INFO
          // ============================================
          _buildSectionHeader('ABOUT'),
          _sectionCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppTheme.accentMint),
                  title: Text('App Version',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text('1.0.0',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
                _tileDivider(),
                ListTile(
                  leading: const Icon(Icons.flight_takeoff,
                      color: AppTheme.accentMint),
                  title: Text('Trip Mint',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text('Travel Budget Planner',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary.withOpacity(0.9),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
