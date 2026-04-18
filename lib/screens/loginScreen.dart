import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fooder/screens/admin_panel_screen.dart';
import 'package:fooder/screens/forgetPwScreen.dart';

import '../const/colors.dart';
import '../screens/homeScreen.dart';
import '../screens/signUpScreen.dart';
import '../utils/helper.dart';
import '../widgets/customTextInput.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = "/loginScreen";

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String get _adminUsername => dotenv.env['ADMIN_USERNAME'] ?? '';
  String get _adminPassword => dotenv.env['ADMIN_PASSWORD'] ?? '';

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final emailOrUser = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _loading = true);
    try {
      if (_adminUsername.isNotEmpty &&
          _adminPassword.isNotEmpty &&
          emailOrUser == _adminUsername &&
          password == _adminPassword) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AdminPanelScreen.routeName);
        return;
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailOrUser,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': credential.user!.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Login failed');
    } catch (e) {
      _showMessage('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: Helper.getScreenHeight(context),
        width: Helper.getScreenWidth(context),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 30,
              ),
              child: Column(
                children: [
                  Text(
                    "Login",
                    style: Helper.getTheme(context).headline6,
                  ),
                  const Spacer(),
                  const Text('Add your details to login'),
                  const Spacer(),
                  CustomTextInput(
                    hintText: "Your email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                  const Spacer(),
                  CustomTextInput(
                    hintText: "password",
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onLogin,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Login"),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .pushReplacementNamed(ForgetPwScreen.routeName);
                    },
                    child: const Text("Forget your password?"),
                  ),
                  const Spacer(
                    flex: 2,
                  ),
                  const Text("or Login With"),
                  const Spacer(),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          const Color(
                            0xFF367FC0,
                          ),
                        ),
                      ),
                      onPressed: () {
                        _showMessage('Facebook login is not configured yet.');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            Helper.getAssetName(
                              "fb.png",
                              "virtual",
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          const Text("Login with Facebook")
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          const Color(
                            0xFFDD4B39,
                          ),
                        ),
                      ),
                      onPressed: () {
                        _showMessage('Google login is not configured yet.');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            Helper.getAssetName(
                              "google.png",
                              "virtual",
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          const Text("Login with Google")
                        ],
                      ),
                    ),
                  ),
                  const Spacer(
                    flex: 4,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .pushReplacementNamed(SignUpScreen.routeName);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an Account?"),
                        Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppColor.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
