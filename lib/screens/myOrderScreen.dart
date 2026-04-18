import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/checkoutScreen.dart';
import 'package:fooder/utils/formatters.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class MyOrderScreen extends StatelessWidget {
  static const routeName = '/myOrderScreen';

  const MyOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
children: [
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                    Expanded(
                      child: Text('My Cart', style: Helper.getTheme(context).headline5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: uid == null
                      ? const Center(child: Text('Please login to continue.'))
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('cart')
                              .orderBy('updatedAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final items = snapshot.data!.docs;
                            if (items.isEmpty) {
                              return const Center(child: Text('Your cart is empty.'));
                            }

                            double subtotal = 0;
                            for (final item in items) {
                              final data = item.data();
                              final price = ((data['price'] as num?) ?? 0).toDouble();
                              final qty = ((data['quantity'] as num?) ?? 1).toInt();
                              subtotal += (price * qty);
                            }
                            const delivery = 40.0;
                            final total = subtotal + delivery;

                            return SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                                child: Column(
                                  children: [
                                    ...items.map((doc) => _CartItemTile(uid: uid, doc: doc)),
                                    const SizedBox(height: 12),
                                    _SummaryRow(label: 'Sub Total', value: AppFormatters.bdt(subtotal)),
                                    const SizedBox(height: 8),
                                    _SummaryRow(label: 'Delivery Cost', value: AppFormatters.bdt(delivery)),
                                    const Divider(height: 30),
                                    _SummaryRow(
                                      label: 'Total',
                                      value: AppFormatters.bdt(total),
                                      highlight: true,
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 50,
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.of(context)
                                            .pushNamed(CheckoutScreen.routeName),
                                        child: const Text('Checkout'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

class _CartItemTile extends StatelessWidget {
  final String uid;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _CartItemTile({required this.uid, required this.doc});

  Future<void> _updateQuantity(int quantity) async {
    if (quantity <= 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(doc.id)
          .delete();
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(doc.id)
        .set({'quantity': quantity, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final name = (data['name'] as String? ?? 'Unnamed Item').trim();
    final imageUrl = (data['imageUrl'] as String? ?? '').trim();
    final price = ((data['price'] as num?) ?? 0).toDouble();
    final qty = ((data['quantity'] as num?) ?? 1).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColor.placeholderBg,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 68,
              height: 68,
              child: imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xfff3f3f3),
                      child: Icon(Icons.fastfood),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xfff3f3f3),
                        child: Icon(Icons.broken_image),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Helper.getTheme(context).headline3),
                const SizedBox(height: 4),
                Text(AppFormatters.bdt(price), style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _updateQuantity(qty - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$qty'),
          IconButton(
            onPressed: () => _updateQuantity(qty + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Helper.getTheme(context).headline3)),
        Text(
          value,
          style: Helper.getTheme(context).headline3?.copyWith(
                color: highlight ? AppColor.orange : AppColor.primary,
                fontSize: highlight ? 22 : null,
              ),
        ),
      ],
    );
  }
}



