import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../const/colors.dart';
import '../utils/formatters.dart';
import '../utils/helper.dart';
import '../widgets/customNavBar.dart';
import '../widgets/searchBar.dart';
import 'individualItem.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/homeScreen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String _dishSort = 'A-Z';

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
              builder: (context, foodSnapshot) {
                if (foodSnapshot.hasError) {
                  return Center(child: Text('Error: ${foodSnapshot.error}'));
                }
                if (!foodSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = foodSnapshot.data!.docs;
                final foods = docs
                    .where((d) {
                      final name = (d.data()['name'] as String? ?? '').toLowerCase();
                      final cat = (d.data()['category'] as String? ?? '').toLowerCase();
                      final q = _search.toLowerCase();
                      return q.isEmpty || name.contains(q) || cat.contains(q);
                    })
                    .toList();

                final popular = [...foods]
                  ..sort((a, b) {
                    final ar = ((a.data()['rating'] as num?) ?? 0).toDouble();
                    final br = ((b.data()['rating'] as num?) ?? 0).toDouble();
                    return br.compareTo(ar);
                  });

                final dishesByName = [...foods]
                  ..sort((a, b) {
                    final an = (a.data()['name'] as String? ?? '').trim().toLowerCase();
                    final bn = (b.data()['name'] as String? ?? '').trim().toLowerCase();
                    return _dishSort == 'A-Z' ? an.compareTo(bn) : bn.compareTo(an);
                  });

                final categories = foods
                    .map((e) => (e.data()['category'] as String? ?? 'General').trim())
                    .where((e) => e.isNotEmpty)
                    .toSet()
                    .toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _GreetingText(),
                            ),
                            const Icon(Icons.shopping_bag_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppSearchBar(title: 'Search Food'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v.trim()),
                          decoration: const InputDecoration(
                            hintText: 'Filter by name/category',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (categories.isNotEmpty)
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemBuilder: (_, i) => Chip(label: Text(categories[i])),
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemCount: categories.length,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('Sort dishes: '),
                            DropdownButton<String>(
                              value: _dishSort,
                              items: const [
                                DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
                                DropdownMenuItem(value: 'Z-A', child: Text('Z-A')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _dishSort = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: 'Popular Foods',
                        trailing: '${popular.length} items',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: popular.isEmpty
                            ? const _EmptyState(text: 'No foods available yet.')
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemBuilder: (_, i) => _PopularCard(doc: popular[i]),
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemCount: popular.length > 10 ? 10 : popular.length,
                              ),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: 'Dishes',
                        trailing: '${dishesByName.length} items',
                      ),
                      const SizedBox(height: 8),
                      if (dishesByName.isEmpty)
                        const _EmptyState(text: 'No recent items found.')
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: dishesByName
                                .take(8)
                                .map((doc) => _RecentItemCard(doc: doc))
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar(home: true)),
        ],
      ),
    );
  }
}

class _GreetingText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Text('Welcome to Meal Monkey', style: Helper.getTheme(context).headline5);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final name = snapshot.data?.data()?['name'] as String?;
        return Text(
          'Good day${(name == null || name.trim().isEmpty) ? '' : ', ${name.trim()}'}!',
          style: Helper.getTheme(context).headline5,
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionTitle({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Helper.getTheme(context).headline5),
          Text(trailing, style: TextStyle(color: AppColor.secondary)),
        ],
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _PopularCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final imageUrl = (data['imageUrl'] as String? ?? '').trim();
    final name = (data['name'] as String? ?? 'Unnamed Item').trim();
    final category = (data['category'] as String? ?? 'General').trim();
    final rating = ((data['rating'] as num?) ?? 0).toDouble();
    final price = ((data['price'] as num?) ?? 0).toDouble();

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(IndividualItem.routeName, arguments: doc.id),
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 190,
                width: 280,
                child: imageUrl.isEmpty
                    ? const ColoredBox(
                        color: Color(0xfff3f3f3),
                        child: Icon(Icons.fastfood, size: 50),
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
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Helper.getTheme(context).headline4?.copyWith(color: AppColor.primary),
            ),
            Row(
              children: [
                Text(category),
                const SizedBox(width: 8),
                Icon(Icons.star, color: AppColor.orange, size: 15),
                const SizedBox(width: 4),
                Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColor.orange)),
                const Spacer(),
                Text(AppFormatters.bdt(price), style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _RecentItemCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final imageUrl = (data['imageUrl'] as String? ?? '').trim();
    final name = (data['name'] as String? ?? 'Unnamed Item').trim();
    final category = (data['category'] as String? ?? 'General').trim();
    final rating = ((data['rating'] as num?) ?? 0).toDouble();
    final price = ((data['price'] as num?) ?? 0).toDouble();

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(IndividualItem.routeName, arguments: doc.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 78,
                height: 78,
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
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Helper.getTheme(context).headline4?.copyWith(color: AppColor.primary)),
                  const SizedBox(height: 4),
                  Text(category),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColor.orange, size: 15),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppColor.orange)),
                      const Spacer(),
                      Text(AppFormatters.bdt(price), style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: AppColor.secondary),
        ),
      ),
    );
  }
}



