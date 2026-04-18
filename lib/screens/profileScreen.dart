import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/landingScreen.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profileScreen';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _occupationController = TextEditingController();
  final _dobController = TextEditingController();
  String _gender = 'Prefer not to say';
  bool _initialized = false;
  bool _saving = false;

  Future<void> _saveProfile(String uid) async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'address':
            '${_addressLine1Controller.text.trim()} ${_addressLine2Controller.text.trim()}'
                .trim(),
        'gender': _gender,
        'dateOfBirth': _dobController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (_) => false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _occupationController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
children: [
          SafeArea(
            child: uid == null
                ? const Center(child: Text('Please login first.'))
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();
                      if (data != null && !_initialized) {
                        _nameController.text = (data['name'] as String? ?? '').trim();
                        _emailController.text = (data['email'] as String? ?? '').trim();
                        _phoneController.text = (data['phone'] as String? ?? '').trim();
                        _addressLine1Controller.text =
                            (data['addressLine1'] as String? ?? '').trim();
                        _addressLine2Controller.text =
                            (data['addressLine2'] as String? ?? '').trim();
                        _occupationController.text =
                            (data['occupation'] as String? ?? '').trim();
                        _dobController.text = (data['dateOfBirth'] as String? ?? '').trim();
                        final loadedGender =
                            (data['gender'] as String? ?? 'Prefer not to say').trim();
                        const allowedGender = [
                          'Male',
                          'Female',
                          'Other',
                          'Prefer not to say'
                        ];
                        _gender = allowedGender.contains(loadedGender)
                            ? loadedGender
                            : 'Prefer not to say';
                        _initialized = true;
                      }

                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Profile', style: Helper.getTheme(context).headline5),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const CircleAvatar(
                                radius: 44,
                                backgroundColor: AppColor.placeholderBg,
                                child: Icon(Icons.person, size: 46, color: AppColor.secondary),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _nameController.text.isEmpty
                                    ? 'Meal Monkey User'
                                    : 'Hi, ${_nameController.text}!',
                                style: Helper.getTheme(context)
                                    .headline4
                                    ?.copyWith(color: AppColor.primary),
                              ),
                              const SizedBox(height: 28),
                              _ProfileField(label: 'Name', controller: _nameController),
                              const SizedBox(height: 14),
                              _ProfileField(
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: false,
                              ),
                              const SizedBox(height: 14),
                              _ProfileField(
                                label: 'Mobile No',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: ShapeDecoration(
                                  color: AppColor.placeholderBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _gender,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Male',
                                        child: Text('Gender: Male'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Female',
                                        child: Text('Gender: Female'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Other',
                                        child: Text('Gender: Other'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Prefer not to say',
                                        child: Text('Gender: Prefer not to say'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _gender = v);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _ProfileField(
                                label: 'Address Line 1',
                                controller: _addressLine1Controller,
                              ),
                              const SizedBox(height: 14),
                              _ProfileField(
                                label: 'Address Line 2',
                                controller: _addressLine2Controller,
                              ),
                              const SizedBox(height: 14),
                              _ProfileField(
                                label: 'Date of Birth (DD/MM/YYYY)',
                                controller: _dobController,
                                keyboardType: TextInputType.datetime,
                              ),
                              const SizedBox(height: 14),
                              _ProfileField(
                                label: 'Occupation',
                                controller: _occupationController,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : () => _saveProfile(uid),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Save'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _signOut,
                                  icon: const Icon(Icons.power_settings_new),
                                  label: const Text('Logout'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar(profile: true)),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool enabled;

  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColor.placeholderBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}



