import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/homeScreen.dart';
import 'package:fooder/screens/myOrderScreen.dart';
import 'package:fooder/utils/formatters.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkoutScreen';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  bool _addressLoaded = false;
  bool _placingOrder = false;

  Future<void> _placeOrder(List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address is required.')),
      );
      return;
    }

    setState(() => _placingOrder = true);
    try {
      double subtotal = 0;
      final items = <Map<String, dynamic>>[];
      for (final doc in cartItems) {
        final data = doc.data();
        final price = ((data['price'] as num?) ?? 0).toDouble();
        final quantity = ((data['quantity'] as num?) ?? 1).toInt();
        subtotal += price * quantity;
        items.add({
          'foodId': data['foodId'] ?? doc.id,
          'name': data['name'] ?? '',
          'price': price,
          'quantity': quantity,
          'imageUrl': data['imageUrl'] ?? '',
        });
      }
      const delivery = 40.0;
      final total = subtotal + delivery;

      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'userEmail': user.email,
        'address': address,
        'status': 'pending',
        'total': total,
        'subtotal': subtotal,
        'deliveryCost': delivery,
        'currency': 'BDT',
        'paymentMethod': 'cash_on_delivery',
        'items': items,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in cartItems) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      showModalBottomSheet(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return SizedBox(
            height: Helper.getScreenHeight(context) * 0.62,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const SizedBox(height: 10),
                const Icon(Icons.check_circle, color: Colors.green, size: 70),
                const SizedBox(height: 12),
                Text('Thank You!',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    )),
                const SizedBox(height: 6),
                Text('Your order is confirmed', style: Helper.getTheme(context).headline4),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'We are preparing your food now. You can track order status from My Orders.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil(MyOrderScreen.routeName, (_) => false),
                      child: const Text('Track My Order'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(HomeScreen.routeName, (_) => false),
                  child: Text('Back To Home',
                      style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
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
                    builder: (context, userSnapshot) {
                      final userData = userSnapshot.data?.data();
                      if (!_addressLoaded && userData != null) {
                        final line1 = (userData['addressLine1'] as String? ?? '').trim();
                        final line2 = (userData['addressLine2'] as String? ?? '').trim();
                        final merged = '$line1 $line2'.trim();
                        _addressController.text =
                            merged.isEmpty ? (userData['address'] as String? ?? '').trim() : merged;
                        _addressLoaded = true;
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('cart')
                            .snapshots(),
                        builder: (context, cartSnapshot) {
                          if (cartSnapshot.hasError) {
                            return Center(child: Text('Error: ${cartSnapshot.error}'));
                          }
                          if (!cartSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final cartItems = cartSnapshot.data!.docs;
                          if (cartItems.isEmpty) {
                            return const Center(child: Text('Your cart is empty.'));
                          }

                          double subtotal = 0;
                          for (final doc in cartItems) {
                            final data = doc.data();
                            final price = ((data['price'] as num?) ?? 0).toDouble();
                            final qty = ((data['quantity'] as num?) ?? 1).toInt();
                            subtotal += price * qty;
                          }
                          const delivery = 40.0;
                          final total = subtotal + delivery;

                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        icon: const Icon(Icons.arrow_back_ios_rounded),
                                      ),
                                      Expanded(
                                        child: Text('Checkout', style: Helper.getTheme(context).headline5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text('Delivery Address', style: Helper.getTheme(context).headline4),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _addressController,
                                    minLines: 2,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColor.placeholderBg,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text('Payment Method', style: Helper.getTheme(context).headline4),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColor.placeholderBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Cash on delivery'),
                                        Icon(Icons.check_circle, color: AppColor.orange),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text('Order Items', style: Helper.getTheme(context).headline4),
                                  const SizedBox(height: 10),
                                  ...cartItems.map((doc) {
                                    final data = doc.data();
                                    final name = (data['name'] as String? ?? 'Item').trim();
                                    final price = ((data['price'] as num?) ?? 0).toDouble();
                                    final qty = ((data['quantity'] as num?) ?? 1).toInt();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text('$name x$qty')),
                                          Text(AppFormatters.bdt(price * qty)),
                                        ],
                                      ),
                                    );
                                  }),
                                  const Divider(height: 26),
                                  _PriceRow(label: 'Sub Total', value: AppFormatters.bdt(subtotal)),
                                  const SizedBox(height: 6),
                                  _PriceRow(label: 'Delivery Cost', value: AppFormatters.bdt(delivery)),
                                  const Divider(height: 26),
                                  _PriceRow(label: 'Total', value: AppFormatters.bdt(total), emphasize: true),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _placingOrder ? null : () => _placeOrder(cartItems),
                                      child: _placingOrder
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Place Order'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar()),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _PriceRow({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? AppColor.orange : AppColor.primary,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}



