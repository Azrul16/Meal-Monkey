import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/individualItem.dart';
import 'package:fooder/utils/formatters.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';
import 'package:fooder/widgets/searchBar.dart';

class DessertScreen extends StatefulWidget {
  static const routeName = '/dessertScreen';

  const DessertScreen({super.key});

  @override
  State<DessertScreen> createState() => _DessertScreenState();
}

class _DessertScreenState extends State<DessertScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final categoryArg = (ModalRoute.of(context)?.settings.arguments as String?)?.trim();
    final category = (categoryArg == null || categoryArg.isEmpty) ? 'Desserts' : categoryArg;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColor.primary),
                      ),
                      Expanded(child: Text(category, style: Helper.getTheme(context).headline5)),
                      const Icon(Icons.shopping_bag_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppSearchBar(title: 'Search Food'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Filter food items',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
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

                      final items = snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        final docCategory = (data['category'] as String? ?? '').toLowerCase();
                        final name = (data['name'] as String? ?? '').toLowerCase();
                        final matchesCategory = docCategory == category.toLowerCase();
                        final matchesSearch = _search.isEmpty || name.contains(_search);
                        return matchesCategory && matchesSearch;
                      }).toList();

                      if (items.isEmpty) {
                        return Center(child: Text('No items available in $category.'));
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _DessertCard(doc: items[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar(menu: true)),
        ],
      ),
    );
  }
}

class _DessertCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _DessertCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final imageUrl = (data['imageUrl'] as String? ?? '').trim();
    final name = (data['name'] as String? ?? 'Unnamed Item').trim();
    final rating = ((data['rating'] as num?) ?? 0).toDouble();
    final price = ((data['price'] as num?) ?? 0).toDouble();

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(IndividualItem.routeName, arguments: doc.id),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
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
            ),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.70), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Helper.getTheme(context).headline4?.copyWith(color: Colors.white),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColor.orange, size: 15),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColor.orange)),
                      const Spacer(),
                      Text(
                        AppFormatters.bdt(price),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
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



