import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/animated_glass_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/royal_design_system.dart';
import '../../../widgets/noteshub_app_bar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          SignInRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your administrator email first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(PasswordResetRequested(email));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient background
          const Positioned.fill(
            child: PremiumAnimatedGlassBackground(),
          ),

          // Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  const NotesHubAppBar(
                    title: 'Administrator Sign In',
                    subtitle: 'Authorized Author & Owner access only',
                  ),

                  // Login Form Center Card
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xE60D1630) : const Color(0xF2FAF7F0),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark ? RoyalColors.glassGoldBorder : RoyalColors.ivoryBorder,
                                    width: 1.4,
                                  ),
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color: RoyalColors.royalGold.withValues(alpha: 0.1),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          ),
                                          const BoxShadow(
                                            color: Color(0x66000000),
                                            blurRadius: 20,
                                            offset: Offset(0, 6),
                                          ),
                                        ]
                                      : RoyalShadows.glassGlow,
                                ),
                                child: BlocConsumer<AuthBloc, AuthState>(
                                  listener: (context, state) {
                                    if (state is Authenticated) {
                                      if (state.isAuthor) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Signed in as ${state.user.name ?? "Administrator"}. Admin controls active.'),
                                            backgroundColor: RoyalColors.emeraldActive,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        } else {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Access denied: You do not have an author or owner role.'),
                                            backgroundColor: Color(0xFFDC2626),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } else if (state is AuthFailure) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(state.message),
                                          backgroundColor: const Color(0xFFDC2626),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else if (state is PasswordResetSent) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Password reset instructions sent to ${state.email}.'),
                                          backgroundColor: RoyalColors.emeraldActive,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;

                                    return Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Gold Squircle Emblem Header
                                          Center(
                                            child: Container(
                                              width: 58,
                                              height: 58,
                                              decoration: BoxDecoration(
                                                gradient: RoyalGradients.metallicGold,
                                                borderRadius: BorderRadius.circular(18),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: RoyalColors.royalGold.withValues(alpha: 0.4),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.admin_panel_settings_rounded,
                                                size: 30,
                                                color: RoyalColors.midnightNavy,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          // Title & Subtitle
                                          ShaderMask(
                                            shaderCallback: (bounds) =>
                                                RoyalGradients.goldShimmer.createShader(bounds),
                                            child: const Text(
                                              'Administrator Portal',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Sign in to manage academic subjects and study materials',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? RoyalColors.textSlateMuted
                                                  : RoyalColors.textNavyMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          // Student Open Access Reassurance Banner
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0x33101B3B)
                                                  : const Color(0x4DC5A04A),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark
                                                    ? RoyalColors.glassGoldBorder
                                                    : RoyalColors.ivoryBorder,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.info_outline_rounded,
                                                  size: 16,
                                                  color: RoyalColors.royalGold,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Student Open Access: NOTEShub does not require a login for browsing or downloads.',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark
                                                          ? RoyalColors.champagne
                                                          : const Color(0xFF8A6715),
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Email Field
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            autocorrect: false,
                                            style: TextStyle(
                                              color: isDark
                                                  ? RoyalColors.pearlWhite
                                                  : RoyalColors.midnightNavy,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Admin Email',
                                              labelStyle: TextStyle(
                                                color: isDark
                                                    ? RoyalColors.champagne
                                                    : const Color(0xFF8A6715),
                                              ),
                                              hintText: 'author@noteshub.app',
                                              hintStyle: TextStyle(
                                                color: isDark
                                                    ? RoyalColors.textDisabled
                                                    : RoyalColors.textNavySubtle,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.email_outlined,
                                                size: 18,
                                                color: RoyalColors.royalGold,
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? const Color(0x33090F22)
                                                  : Colors.white.withValues(alpha: 0.8),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? RoyalColors.glassGoldBorder
                                                      : RoyalColors.ivoryBorder,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: RoyalColors.royalGold,
                                                  width: 1.6,
                                                ),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Please enter your email.';
                                              }
                                              if (!value.contains('@')) {
                                                return 'Please enter a valid email address.';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          // Password Field
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            style: TextStyle(
                                              color: isDark
                                                  ? RoyalColors.pearlWhite
                                                  : RoyalColors.midnightNavy,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              labelStyle: TextStyle(
                                                color: isDark
                                                    ? RoyalColors.champagne
                                                    : const Color(0xFF8A6715),
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.lock_outline_rounded,
                                                size: 18,
                                                color: RoyalColors.royalGold,
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_off_outlined
                                                      : Icons.visibility_outlined,
                                                  size: 18,
                                                  color: isDark
                                                      ? RoyalColors.textSlateMuted
                                                      : RoyalColors.textNavyMuted,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword = !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? const Color(0x33090F22)
                                                  : Colors.white.withValues(alpha: 0.8),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? RoyalColors.glassGoldBorder
                                                      : RoyalColors.ivoryBorder,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: RoyalColors.royalGold,
                                                  width: 1.6,
                                                ),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Please enter your password.';
                                              }
                                              if (value.length < 6) {
                                                return 'Password must be at least 6 characters.';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) => _submitLogin(),
                                          ),

                                          // Forgot password link
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: isLoading ? null : _handleForgotPassword,
                                              child: Text(
                                                'Forgot password?',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? RoyalColors.champagne
                                                      : const Color(0xFF8A6715),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Submit Button
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: RoyalGradients.metallicGold,
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: RoyalColors.royalGold.withValues(alpha: 0.4),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: isLoading ? null : _submitLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                foregroundColor: RoyalColors.midnightNavy,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                              ),
                                              child: isLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: RoyalColors.midnightNavy,
                                                      ),
                                                    )
                                                  : const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.login_rounded, size: 18),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Sign In to Admin Portal',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w800,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}
