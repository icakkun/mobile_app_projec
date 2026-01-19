import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Sign up
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Update display name
        if (_nameController.text.trim().isNotEmpty) {
          await FirebaseAuth.instance.currentUser?.updateDisplayName(
            _nameController.text.trim(),
          );
        }
      }

      // Navigation happens automatically via AuthGate StreamBuilder
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    OutlineInputBorder outline(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: 1.1),
        );

    InputDecoration fieldDeco({
      required String label,
      required String hint,
      required IconData icon,
      Widget? suffix,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.accentMint),
        suffixIcon: suffix,
        floatingLabelStyle: TextStyle(
          color: AppTheme.accentMint.withOpacity(0.95),
          fontWeight: FontWeight.w600,
        ),
        labelStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.9)),
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.55)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: outline(Colors.white.withOpacity(0.18)),
        focusedBorder: outline(AppTheme.accentMint.withOpacity(0.65)),
        errorBorder: outline(AppTheme.errorColor.withOpacity(0.70)),
        focusedErrorBorder: outline(AppTheme.errorColor.withOpacity(0.85)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
    }

    // little helper for "glass shine" overlay
    Widget shineOverlay({double opacity = 0.12}) {
      return IgnorePointer(
        child: Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity),
                  Colors.transparent,
                  Colors.white.withOpacity(opacity * 0.35),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Subtle mint glow blobs (no theme color changes)
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentMint.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentMint.withOpacity(0.08),
              ),
            ),
          ),
          // blur the blobs slightly
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentMint.withOpacity(0.25),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/trip_mint_logo.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: -0.1),

                          //Text(
                          // 'Trip Mint',
                          // textAlign: TextAlign.center,
                          //style: theme.textTheme.headlineLarge?.copyWith(
                          //  color: AppTheme.accentMint,
                          // fontWeight: FontWeight.w800,
                          //letterSpacing: 0.3,
                          // ),
                          //),

                          Text(
                            _isLogin ? 'Welcome back' : 'Create your account',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .scale(begin: const Offset(0.9, 0.9)),
                          //.animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // Glass card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Stack(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 18, 18, 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 30,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // segmented toggle (UI only)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.10),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _ModeChip(
                                                label: 'Log In',
                                                selected: _isLogin,
                                                onTap: _isLoading
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _isLogin = true;
                                                          _errorMessage = null;
                                                          // keep values
                                                        });
                                                      },
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: _ModeChip(
                                                label: 'Sign Up',
                                                selected: !_isLogin,
                                                onTap: _isLoading
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _isLogin = false;
                                                          _errorMessage = null;
                                                        });
                                                      },
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(delay: 250.ms)
                                          .slideX(begin: 0.1),

                                      const SizedBox(height: 18),

                                      if (!_isLogin) ...[
                                        TextFormField(
                                          controller: _nameController,
                                          decoration: fieldDeco(
                                            label: 'Name',
                                            hint: 'Your name',
                                            icon: Icons.person,
                                          ),
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                          ),
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (!_isLogin &&
                                                (value == null ||
                                                    value.trim().isEmpty)) {
                                              return 'Please enter your name';
                                            }
                                            return null;
                                          },
                                        )
                                            .animate()
                                            .fadeIn(delay: 200.ms)
                                            .slideX(begin: 0.1),
                                        const SizedBox(height: 14),
                                      ],

                                      TextFormField(
                                        controller: _emailController,
                                        decoration: fieldDeco(
                                          label: 'Email',
                                          hint: 'your@email.com',
                                          icon: Icons.email,
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!value.contains('@') ||
                                              !value.contains('.')) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 350.ms)
                                          .slideX(begin: 0.1),

                                      const SizedBox(height: 14),

                                      // ✅ Password + eye
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: fieldDeco(
                                          label: 'Password',
                                          hint: _isLogin
                                              ? 'Your password'
                                              : 'At least 6 characters',
                                          icon: Icons.lock,
                                          suffix: IconButton(
                                            onPressed: () {
                                              setState(() => _obscurePassword =
                                                  !_obscurePassword);
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                        obscureText: _obscurePassword,
                                        textInputAction: _isLogin
                                            ? TextInputAction.done
                                            : TextInputAction.next,
                                        onFieldSubmitted: (_) =>
                                            _isLogin ? _submitForm() : null,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (!_isLogin && value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 400.ms)
                                          .slideX(begin: 0.1),

                                      // ✅ Confirm Password ONLY for signup + eye
                                      if (!_isLogin) ...[
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          decoration: fieldDeco(
                                            label: 'Confirm Password',
                                            hint: 'Re-enter password',
                                            icon: Icons.lock_outline,
                                            suffix: IconButton(
                                              onPressed: () {
                                                setState(() =>
                                                    _obscureConfirmPassword =
                                                        !_obscureConfirmPassword);
                                              },
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                          ),
                                          obscureText: _obscureConfirmPassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) =>
                                              _submitForm(),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please confirm your password';
                                            }
                                            if (value.trim() !=
                                                _passwordController.text
                                                    .trim()) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        )
                                            .animate()
                                            .fadeIn(delay: 450.ms)
                                            .slideX(begin: 0.1),
                                      ],

                                      // Error message
                                      if (_errorMessage != null) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor
                                                .withOpacity(0.10),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.errorColor
                                                  .withOpacity(0.30),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: AppTheme.errorColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: AppTheme.errorColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                            .animate()
                                            .fadeIn(delay: 250.ms)
                                            .slideX(begin: 0.1),
                                      ],

                                      const SizedBox(height: 18),

                                      // ✅ Modern hollow/outline button (still calls _submitForm)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: OutlinedButton(
                                          onPressed:
                                              _isLoading ? null : _submitForm,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.accentMint,
                                            side: BorderSide(
                                              color: AppTheme.accentMint
                                                  .withOpacity(0.85),
                                              width: 1.3,
                                            ),
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppTheme.accentMint,
                                                  ),
                                                )
                                              : Text(
                                                  _isLogin
                                                      ? 'Log In'
                                                      : 'Sign Up',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(delay: 500.ms)
                                          .slideX(begin: 0.1),

                                      const SizedBox(height: 10),

                                      // Secondary toggle (keep same behavior)
                                      TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                setState(() {
                                                  _isLogin = !_isLogin;
                                                  _errorMessage = null;

                                                  // optional cleanup
                                                  _confirmPasswordController
                                                      .clear();
                                                });
                                              },
                                        child: Text(
                                          _isLogin
                                              ? "Don't have an account? Sign Up"
                                              : 'Already have an account? Log In',
                                          style: TextStyle(
                                            color: AppTheme.accentMint,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ✅ just adds a shiny glass highlight, does not change your logic
                              shineOverlay(opacity: 0.14),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Secure sign-in powered by Firebase',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentMint.withOpacity(0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.accentMint.withOpacity(0.40)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.accentMint : AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
