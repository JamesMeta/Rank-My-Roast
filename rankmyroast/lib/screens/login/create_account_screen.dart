import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rankmyroast/classes/mixin/snackbar_service.dart';
import 'package:rankmyroast/screens/login/classes/clipped_container.dart';
import 'package:rankmyroast/screens/login/classes/login_screen_theme.dart';
import 'package:rankmyroast/screens/login/classes/sign_in_with_google.dart';
import 'package:rankmyroast/services/supabase_helper.dart';

const serverClientId =
    "474584121880-5f7qh4hd4eonbpirt35mnddrlmahma9n.apps.googleusercontent.com";

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SnackbarService {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isGoogleLoading = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Center(
              child: Container(decoration: BoxDecoration(color: Colors.green)),
            ),

            Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipPath(
                      clipper: ClippedContainer(),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.080,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Rank My Roast",
                                          style:
                                              LoginScreenTheme.titleTextStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          "Created By James Mata",
                                          style:
                                              LoginScreenTheme.creditTextStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(
                                child: Image.asset(
                                  "assets/images/rankmyroast_icon4.png",
                                  width: screenWidth * 0.5,
                                ),
                              ),

                              SizedBox(
                                height: LoginScreenTheme.sizeBoxSpacingHeight,
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Create Account",
                                    textAlign: TextAlign.start,
                                    style: LoginScreenTheme.sectionTitleStyle,
                                  ),

                                  SizedBox(
                                    height:
                                        LoginScreenTheme.sizeBoxSpacingHeight,
                                  ),

                                  Container(
                                    height:
                                        LoginScreenTheme
                                            .textFieldContainerHeight,
                                    width:
                                        LoginScreenTheme
                                            .textFieldContainerWidth,
                                    alignment:
                                        Alignment
                                            .center, // Vertically centers the "collapsed" field
                                    decoration:
                                        LoginScreenTheme
                                            .textFieldContainerDecoration,
                                    child: TextField(
                                      controller: _emailController,
                                      decoration:
                                          LoginScreenTheme.textfieldInputDecoration(
                                            "Email",
                                          ),
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        LoginScreenTheme.sizeBoxSpacingHeight,
                                  ),

                                  Container(
                                    height:
                                        LoginScreenTheme
                                            .textFieldContainerHeight,
                                    width:
                                        LoginScreenTheme
                                            .textFieldContainerWidth,
                                    alignment:
                                        Alignment
                                            .center, // Vertically centers the "collapsed" field
                                    decoration:
                                        LoginScreenTheme
                                            .textFieldContainerDecoration,
                                    child: TextField(
                                      controller: _passwordController,
                                      decoration:
                                          LoginScreenTheme.textfieldInputDecoration(
                                            "Password",
                                          ),
                                      obscureText: true,
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        LoginScreenTheme.sizeBoxSpacingHeight,
                                  ),

                                  Container(
                                    height:
                                        LoginScreenTheme
                                            .textFieldContainerHeight,
                                    width:
                                        LoginScreenTheme
                                            .textFieldContainerWidth,
                                    alignment:
                                        Alignment
                                            .center, // Vertically centers the "collapsed" field
                                    decoration:
                                        LoginScreenTheme
                                            .textFieldContainerDecoration,
                                    child: TextField(
                                      controller: _confirmPasswordController,
                                      decoration:
                                          LoginScreenTheme.textfieldInputDecoration(
                                            "Confirm Password",
                                          ),
                                      obscureText: true,
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        LoginScreenTheme.sizeBoxSpacingHeight,
                                  ),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_isLoading) return;
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        await _handleCreateAccount();
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      },
                                      style:
                                          LoginScreenTheme.elevatedButtonStyle,
                                      child:
                                          _isLoading
                                              ? CircularProgressIndicator()
                                              : Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Text(
                                                  "Create Account",
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        LoginScreenTheme.sizeBoxSpacingHeight,
                                  ),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_isGoogleLoading) return;
                                        setState(() {
                                          _isGoogleLoading = true;
                                        });
                                        await SignInWithGoogle.handleSignInWithGoogle(
                                          context,
                                        );
                                        setState(() {
                                          _isGoogleLoading = false;
                                        });
                                      },
                                      style:
                                          LoginScreenTheme
                                              .elevatedGoogleButtonStyle,
                                      child:
                                          _isGoogleLoading
                                              ? CircularProgressIndicator()
                                              : Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: IntrinsicHeight(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Flexible(
                                                        flex: 2,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            image: DecorationImage(
                                                              image: NetworkImage(
                                                                "https://cdn-icons-png.flaticon.com/512/2702/2702602.png",
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      Flexible(
                                                        flex: 10,
                                                        child: Text(
                                                          "Continue With Google",
                                                          style: TextStyle(
                                                            fontSize: 18.sp,
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ),
                            ],
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
    );
  }

  Future<void> _handleCreateAccount() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8) {
      showSnackbar(context, 'Error: Password must be at least 8 characters');
      return;
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      showSnackbar(
        context,
        'Error: Password must contain at least one uppercase letter',
      );
      return;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      showSnackbar(context, 'Error: Password must contain at least one number');
      return;
    }

    if (password != confirmPassword) {
      showSnackbar(context, 'Error: Passwords do not match');
      return;
    }

    try {
      final response = await SupabaseHelper.auth.authSignupWithPassword(
        email,
        password,
      );

      if (mounted) {
        if (response.user != null) {
          context.push(
            '/login/create-account/confirm-email',
            extra: [email, password],
          );
        } else {
          showSnackbar(context, 'Error: Unable to create account at this time');
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().toLowerCase().contains("email not confirmed")) {
          context.push(
            "/login/create-account/confirm-email",
            extra: [email, password],
          );
          return;
        }

        if (e.toString().toLowerCase().contains("user already registered")) {
          showSnackbar(
            context,
            'Error: An account with this email already exists',
          );
          return;
        } else {
          showSnackbar(context, 'Error creating account: ${e.toString()}');
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }
}
