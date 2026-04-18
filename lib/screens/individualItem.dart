import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/myOrderScreen.dart';
import 'package:fooder/utils/formatters.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class IndividualItem extends StatefulWidget {
  static const routeName = '/individualScreen';

  const IndividualItem({super.key});

  @override
  State<IndividualItem> createState() => _IndividualItemState();
}

class _IndividualItemState extends State<IndividualItem> {
  int _quantity = 1;
  bool _saving = false;

  Future<void> _addToCart(String foodId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(foodId);

      final existing = await cartRef.get();
      final currentQty = ((existing.data()?['quantity'] as num?) ?? 0).toInt();
      final newQty = currentQty + _quantity;

      await cartRef.set({
        'foodId': foodId,
        'name': data['name'],
        'imageUrl': data['imageUrl'],
        'price': (data['price'] as num?)?.toDouble() ?? 0,
        'category': data['category'],
        'quantity': newQty,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodId = ModalRoute.of(context)?.settings.arguments as String?;
    if (foodId == null || foodId.isEmpty) {
      return Scaffold(
      resizeToAvoidBottomInset: false,
        appBar: AppBar(),
        body: const Center(child: Text('No food selected.')),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('foods').doc(foodId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!.data();
              if (data == null) {
                return const Center(child: Text('Food not found.'));
              }

              final name = (data['name'] as String? ?? 'Unnamed Item').trim();
              final category = (data['category'] as String? ?? 'General').trim();
              final description = (data['description'] as String? ?? 'No description').trim();
              final imageUrl = (data['imageUrl'] as String? ?? '').trim();
              final rating = ((data['rating'] as num?) ?? 0).toDouble();
              final price = ((data['price'] as num?) ?? 0).toDouble();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: Helper.getScreenHeight(context) * 0.45,
                          width: double.infinity,
                          child: imageUrl.isEmpty
                              ? const ColoredBox(
                                  color: Color(0xfff3f3f3),
                                  child: Icon(Icons.fastfood, size: 60),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const ColoredBox(
                                    color: Color(0xfff3f3f3),
                                    child: Icon(Icons.broken_image, size: 48),
                                  ),
                                ),
                        ),
                        Container(
                          height: Helper.getScreenHeight(context) * 0.45,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(MyOrderScreen.routeName);
                                  },
                                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: Helper.getTheme(context).headline5),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(category),
                              const SizedBox(width: 10),
                              Icon(Icons.star, size: 16, color: AppColor.orange),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColor.orange)),
                              const Spacer(),
                              Text(
                                AppFormatters.bdt(price),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Description', style: Helper.getTheme(context).headline4),
                          const SizedBox(height: 8),
                          Text(description),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text('Quantity', style: Helper.getTheme(context).headline4),
                              const Spacer(),
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('$_quantity', style: const TextStyle(fontSize: 16)),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 105,
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('foods').doc(foodId).snapshots(),
              builder: (context, snapshot) {
                final price = ((snapshot.data?.data()?['price'] as num?) ?? 0).toDouble();
                final total = price * _quantity;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.placeholder.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total'),
                            Text(
                              AppFormatters.bdt(total),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                final snap = await FirebaseFirestore.instance
                                    .collection('foods')
                                    .doc(foodId)
                                    .get();
                                if (snap.data() == null) return;
                                await _addToCart(foodId, snap.data()!);
                              },
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Cart'),
                      ),
                    ],
                  ),
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

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: onTap,
        child: Icon(icon, size: 16),
      ),
    );
  }
}



