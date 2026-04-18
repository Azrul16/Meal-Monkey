import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fooder/const/colors.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class PaymentScreen extends StatelessWidget {
  static const routeName = '/paymentScreen';

  const PaymentScreen({super.key});

  Future<void> _openAddMethodDialog(BuildContext context, String uid) async {
    final holder = TextEditingController();
    final last4 = TextEditingController();
    String provider = 'Visa';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Add Payment Method'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: provider,
                    items: const ['Visa', 'Mastercard', 'bKash', 'Nagad']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setLocal(() => provider = v ?? 'Visa'),
                    decoration: const InputDecoration(labelText: 'Provider'),
                  ),
                  TextField(
                    controller: holder,
                    decoration: const InputDecoration(labelText: 'Account/Card Holder'),
                  ),
                  TextField(
                    controller: last4,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(labelText: 'Last 4 digits'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (holder.text.trim().isEmpty || last4.text.trim().length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Provide valid details.')),
                      );
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('payment_methods')
                        .add({
                      'provider': provider,
                      'holder': holder.text.trim(),
                      'last4': last4.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_ios),
                            ),
                            Expanded(
                              child: Text('Payment Details', style: Helper.getTheme(context).headline5),
                            ),
                            const Icon(Icons.shopping_bag_outlined),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'Manage your saved payment methods',
                              style: Helper.getTheme(context).headline3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('payment_methods')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final methods = snapshot.data!.docs;
                            if (methods.isEmpty) {
                              return const Center(child: Text('No saved payment methods.'));
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                              itemCount: methods.length,
                              itemBuilder: (context, index) {
                                final data = methods[index].data();
                                final provider = (data['provider'] as String? ?? 'Card').trim();
                                final holder = (data['holder'] as String? ?? 'Account Holder').trim();
                                final last4 = (data['last4'] as String? ?? '0000').trim();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColor.placeholderBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColor.orange.withOpacity(0.2),
                                        child: Icon(Icons.account_balance_wallet, color: AppColor.orange),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('$provider •••• $last4',
                                                style: const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(holder),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          await methods[index].reference.delete();
                                        },
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openAddMethodDialog(context, uid),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Payment Method'),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar()),
        ],
      ),
    );
  }
}



