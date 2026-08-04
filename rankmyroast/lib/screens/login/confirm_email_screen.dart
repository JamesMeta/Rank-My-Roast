import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/mixin/Snackbar_service.dart';
import 'package:rankmyroast/screens/login/classes/clipped_container.dart';
import 'package:rankmyroast/services/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key, required this.extra});

  final List<String> extra;

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen>
    with SnackbarService {
  late final String email;
  late final String password;
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    email = widget.extra.first;
    password = widget.extra.last;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(color: Colors.green)),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipPath(
                  clipper: ClippedContainer(),
                  child: Container(
                    height: height * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderSection(),
                          const SizedBox(height: 28),
                          _buildCodeInputSection(),
                          const SizedBox(height: 12),
                          _buildVerifyButton(),
                          const SizedBox(height: 12),
                          _buildResendButton(),
                        ],
                      ),
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

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Verify Your Email",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "A confirmation email has been sent to $email",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          "Please enter the 8-digit verification code below.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildCodeInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Verification Code",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 8,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: "00000000",

            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              side: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          maximumSize: WidgetStatePropertyAll(Size(double.infinity, 50.h)),
          minimumSize: WidgetStatePropertyAll(Size(double.infinity, 50.h)),
        ),
        onPressed: _isLoading ? null : _handleVerifyPressed,
        child:
            _isLoading
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                : Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: 18.sp,

                    letterSpacing: 0.5,
                    color: Colors.green,
                  ),
                ),
      ),
    );
  }

  Widget _buildResendButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          if (_isResending) return;
          setState(() {
            _isResending = true;
          });
          _resendCode().whenComplete(() {
            if (mounted) {
              setState(() {
                _isResending = false;
              });
            }
          });
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child:
            _isResending
                ? CircularProgressIndicator()
                : Text(
                  'Didn\'t receive the code? Resend',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  void _handleVerifyPressed() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    _confirmEmail();
  }

  Future<void> _confirmEmail() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _resetLoadingState();
      showSnackbar(context, 'Please enter the verification code.');
      return;
    }

    if (code.length != 8) {
      _resetLoadingState();
      showSnackbar(context, 'Please enter a valid 8-digit code.');
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.signup,
      );

      if (mounted) {
        if (response.session != null) {
          await SupabaseHelper.users.addUser();
          await SupabaseHelper.groups.createPersonalGroup();
          if (mounted) context.go('/base');
        } else {
          _resetLoadingState();
          showSnackbar(context, 'Email confirmation failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _resetLoadingState();
        if (e.toString().toLowerCase().contains('otp_expired')) {
          showSnackbar(context, 'Verification code has expired or is invalid.');
        } else {
          showSnackbar(context, 'Error confirming email: $e');
        }
      }
    }
  }

  void _resetLoadingState() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (mounted) {
        showSuccessSnackbar(
          context,
          'Verification code resent. Please check your email.',
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackbar(context, 'Error resending code: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
