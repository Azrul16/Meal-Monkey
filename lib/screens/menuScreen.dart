import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/dessertScreen.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';
import 'package:fooder/widgets/searchBar.dart';

class MenuScreen extends StatefulWidget {
  static const routeName = '/menuScreen';

  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Menu', style: Helper.getTheme(context).headline5),
                      const Icon(Icons.shopping_bag_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppSearchBar(title: 'Search Category'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Filter categories',
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

                      final Map<String, int> categoryCount = {};
                      for (final doc in snapshot.data!.docs) {
                        final category =
                            (doc.data()['category'] as String? ?? 'General').trim();
                        if (category.isEmpty) continue;
                        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
                      }

                      final categories = categoryCount.entries
                          .where((e) => _search.isEmpty || e.key.toLowerCase().contains(_search))
                          .toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      if (categories.isEmpty) {
                        return const Center(child: Text('No categories found.'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                        itemBuilder: (context, index) {
                          final item = categories[index];
                          return MenuCard(
                            name: item.key,
                            count: item.value.toString(),
                            handler: () {
                              Navigator.of(context).pushNamed(
                                DessertScreen.routeName,
                                arguments: item.key,
                              );
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemCount: categories.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            child: CustomNavBar(menu: true),
          ),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.name,
    required this.count,
    required this.handler,
  });

  final String name;
  final String count;
  final VoidCallback handler;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handler,
      child: Container(
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColor.placeholder.withOpacity(0.35),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColor.orange.withOpacity(0.2),
              child: Icon(Icons.restaurant_menu, color: AppColor.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Helper.getTheme(context)
                          .headline4
                          ?.copyWith(color: AppColor.primary)),
                  const SizedBox(height: 4),
                  Text('$count items'),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}



