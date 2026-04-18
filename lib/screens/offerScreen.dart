import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/individualItem.dart';
import 'package:fooder/utils/formatters.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class OfferScreen extends StatelessWidget {
  static const routeName = '/offerScreen';

  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
children: [
          SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('foods')
                  .where('available', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final offers = snapshot.data!.docs.where((doc) {
                  final discount = ((doc.data()['discountPercent'] as num?) ?? 0).toDouble();
                  return discount > 0;
                }).toList()
                  ..sort((a, b) {
                    final ad = ((a.data()['discountPercent'] as num?) ?? 0).toDouble();
                    final bd = ((b.data()['discountPercent'] as num?) ?? 0).toDouble();
                    return bd.compareTo(ad);
                  });

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Latest Offers', style: Helper.getTheme(context).headline5),
                            const Icon(Icons.shopping_bag_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [Text('Find the best discounts selected by admin')],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (offers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No active offers right now.'),
                        )
                      else
                        ...offers.map((doc) => OfferCard(doc: doc)),
                      const SizedBox(height: 110),
                    ],
                  ),
                );
              },
            ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar(offer: true)),
        ],
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const OfferCard({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final imageUrl = (data['imageUrl'] as String? ?? '').trim();
    final name = (data['name'] as String? ?? 'Unnamed Item').trim();
    final category = (data['category'] as String? ?? 'General').trim();
    final rating = ((data['rating'] as num?) ?? 0).toDouble();
    final discount = ((data['discountPercent'] as num?) ?? 0).toDouble();
    final price = ((data['price'] as num?) ?? 0).toDouble();
    final discounted = (price * ((100 - discount) / 100)).clamp(0, price);

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(IndividualItem.routeName, arguments: doc.id),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: imageUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xfff3f3f3),
                          child: Icon(Icons.fastfood, size: 48),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xfff3f3f3),
                            child: Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColor.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${discount.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Helper.getTheme(context)
                          .headline4
                          ?.copyWith(color: AppColor.primary),
                    ),
                  ),
                  Text(
                    AppFormatters.bdt(discounted),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(category),
                  const SizedBox(width: 8),
                  Icon(Icons.star, size: 15, color: AppColor.orange),
                  const SizedBox(width: 4),
                  Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColor.orange)),
                  const SizedBox(width: 10),
                  Text(
                    AppFormatters.bdt(price),
                    style: TextStyle(
                      color: AppColor.secondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



