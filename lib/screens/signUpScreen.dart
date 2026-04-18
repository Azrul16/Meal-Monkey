import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../const/colors.dart';
import '../screens/homeScreen.dart';
import '../screens/loginScreen.dart';
import '../utils/helper.dart';
import '../widgets/customTextInput.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/signUpScreen';

  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _occupationController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _gender = 'Prefer not to say';
  bool _loading = false;

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _mobileController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'address':
            '${_addressLine1Controller.text.trim()} ${_addressLine2Controller.text.trim()}'
                .trim(),
        'gender': _gender,
        'dateOfBirth': _dobController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Sign up failed');
    } catch (e) {
      _showMessage('Sign up failed: $e');
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
      width: Helper.getScreenWidth(context),
      height: Helper.getScreenHeight(context),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: Column(
              children: [
                Text(
                  "Sign Up",
                  style: Helper.getTheme(context).headline6,
                ),
                const SizedBox(height: 14),
                const Text(
                  "Add your details to sign up",
                ),
                const SizedBox(height: 18),
                CustomTextInput(
                  hintText: "Name",
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Mobile No",
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const ShapeDecoration(
                    color: AppColor.placeholderBg,
                    shape: StadiumBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Gender: Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Gender: Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Gender: Other')),
                        DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Gender: Prefer not to say')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _gender = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Address Line 1",
                  controller: _addressLine1Controller,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Address line 1 is required'
                      : null,
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Address Line 2",
                  controller: _addressLine2Controller,
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Date of Birth (DD/MM/YYYY)",
                  controller: _dobController,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Occupation",
                  controller: _occupationController,
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Password",
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be 6+ characters'
                      : null,
                ),
                const SizedBox(height: 12),
                CustomTextInput(
                  hintText: "Confirm Password",
                  controller: _confirmController,
                  obscureText: true,
                  validator: (v) =>
                      v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onSignUp,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Sign Up"),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .pushReplacementNamed(LoginScreen.routeName);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an Account?"),
                      Text(
                        "Login",
                        style: TextStyle(
                          color: AppColor.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _occupationController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
