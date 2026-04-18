import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/loginScreen.dart';
import 'package:fooder/utils/formatters.dart';

class AdminPanelScreen extends StatefulWidget {
  static const routeName = '/adminPanel';

  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Monkey Admin'),
        backgroundColor: AppColor.orange,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _DashboardTab(),
          _FoodManagementTab(),
          _OrderManagementTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              indicatorColor: AppColor.orange.withOpacity(0.15),
              selectedIndex: _tab,
              onDestinationSelected: (idx) => setState(() => _tab = idx),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.fastfood), label: 'Foods'),
                NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
                  },
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('foods').snapshots(),
      builder: (context, foodSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, orderSnap) {
            if (!foodSnap.hasData || !orderSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final foods = foodSnap.data!.docs;
            final orders = orderSnap.data!.docs;
            final pending = orders.where((o) {
              final s = (o.data()['status'] as String? ?? 'pending');
              return s != 'delivered' && s != 'cancelled';
            }).length;
            final revenue = orders.fold<double>(0, (sum, order) {
              return sum + ((order.data()['total'] as num?) ?? 0).toDouble();
            });

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MetricCard(title: 'Total Foods', value: '${foods.length}', icon: Icons.fastfood),
                _MetricCard(title: 'Total Orders', value: '${orders.length}', icon: Icons.receipt_long),
                _MetricCard(title: 'Active Orders', value: '$pending', icon: Icons.timelapse),
                _MetricCard(title: 'Gross Sales', value: AppFormatters.bdt(revenue), icon: Icons.payments),
                const SizedBox(height: 8),
                const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                if (orders.isEmpty)
                  const Text('No orders yet.')
                else
                  ...orders.take(8).map((order) {
                    final data = order.data();
                    final status = (data['status'] as String? ?? 'pending').replaceAll('_', ' ');
                    final total = ((data['total'] as num?) ?? 0).toDouble();
                    return Card(
                      child: ListTile(
                        title: Text('Order ${order.id.substring(0, 6)}'),
                        subtitle: Text('Status: $status'),
                        trailing: Text(AppFormatters.bdt(total)),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColor.orange),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _FoodManagementTab extends StatelessWidget {
  const _FoodManagementTab();
  static const List<String> _defaultCategories = [
    'Burgers',
    'Pizza',
    'Desserts',
    'Beverages',
    'Snacks',
    'Salads',
    'Pasta',
    'General',
  ];

  String _normalizeImageUrl(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;

    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return raw;
    }

    final host = uri.host.toLowerCase();

    // Google Drive share link -> direct content link
    if (host.contains('drive.google.com')) {
      final idFromQuery = uri.queryParameters['id'];
      final segments = uri.pathSegments;
      String? idFromPath;
      for (var i = 0; i < segments.length - 1; i++) {
        if (segments[i] == 'd') {
          idFromPath = segments[i + 1];
          break;
        }
      }
      final fileId = (idFromQuery ?? idFromPath)?.trim();
      if (fileId != null && fileId.isNotEmpty) {
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    }

    // Dropbox share link -> direct raw file link
    if (host == 'dropbox.com' || host == 'www.dropbox.com') {
      return uri.replace(host: 'dl.dropboxusercontent.com', queryParameters: {}).toString();
    }
    if (host == 'dl.dropbox.com') {
      return uri.replace(host: 'dl.dropboxusercontent.com', queryParameters: {}).toString();
    }

    return raw;
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openFoodDialog(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? existing,
    List<String> categoryOptions = const [],
  }) async {
    final name = TextEditingController(text: existing?.data()?['name'] as String? ?? '');
    final existingCategory = (existing?.data()?['category'] as String? ?? '').trim();
    final mergedCategories = <String>[
      ..._defaultCategories,
      ...categoryOptions,
      if (existingCategory.isNotEmpty) existingCategory,
    ].toSet().toList();
    String selectedCategory = existingCategory.isNotEmpty
        ? existingCategory
        : (mergedCategories.contains('General') ? 'General' : mergedCategories.first);
    final imageUrl = TextEditingController(text: existing?.data()?['imageUrl'] as String? ?? '');
    final description =
        TextEditingController(text: existing?.data()?['description'] as String? ?? '');
    final price =
        TextEditingController(text: (existing?.data()?['price'] as num?)?.toString() ?? '');
    final rating =
        TextEditingController(text: (existing?.data()?['rating'] as num?)?.toString() ?? '0');
    final discount = TextEditingController(
      text: (existing?.data()?['discountPercent'] as num?)?.toString() ?? '0',
    );
    bool available = (existing?.data()?['available'] as bool?) ?? true;
    bool saving = false;
    final isEditing = existing != null;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setLocal) {
          final previewUrl = _normalizeImageUrl(imageUrl.text);
          return AlertDialog(
            title: Text(existing == null ? 'Add Food' : 'Edit Food'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  DropdownButtonFormField<String>(
                    value: mergedCategories.contains(selectedCategory) ? selectedCategory : null,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: mergedCategories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setLocal(() => selectedCategory = value);
                    },
                  ),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (BDT)'),
                  ),
                  TextField(
                    controller: rating,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Rating (0-5)'),
                  ),
                  TextField(
                    controller: discount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Discount %'),
                  ),
                  TextField(
                    controller: imageUrl,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  TextField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: available,
                    onChanged: (v) => setLocal(() => available = v),
                    title: const Text('Available'),
                  ),
                  if (previewUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(color: Color(0xfff3f3f3)),
                            child: Image.network(
                              previewUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                              },
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Could not load image. Use a direct image URL.'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColor.orange, foregroundColor: Colors.white),
                onPressed: saving
                    ? null
                    : () async {
                        setLocal(() => saving = true);
                  final parsedPrice = double.tryParse(price.text.trim());
                  final parsedRating = double.tryParse(rating.text.trim()) ?? 0;
                  final parsedDiscount = double.tryParse(discount.text.trim()) ?? 0;
                  final trimmedUrl = _normalizeImageUrl(imageUrl.text);
                  final parsedUrl = Uri.tryParse(trimmedUrl);
                  if (name.text.trim().isEmpty || parsedPrice == null) {
                    _showMessage(context, 'Name and valid price are required.');
                    setLocal(() => saving = false);
                    return;
                  }
                  if (trimmedUrl.isEmpty ||
                      parsedUrl == null ||
                      !(trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'))) {
                    _showMessage(context, 'Provide a valid image URL.');
                    setLocal(() => saving = false);
                    return;
                  }
                  imageUrl.text = trimmedUrl;

                  final payload = {
                    'name': name.text.trim(),
                    'category': selectedCategory.trim(),
                    'price': parsedPrice,
                    'currency': 'BDT',
                    'rating': parsedRating.clamp(0, 5),
                    'discountPercent': parsedDiscount.clamp(0, 90),
                    'imageUrl': trimmedUrl,
                    'description': description.text.trim(),
                    'available': available,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                        try {
                          if (isEditing) {
                            await FirebaseFirestore.instance
                                .collection('foods')
                                .doc(existing.id)
                                .update(payload);
                          } else {
                            await FirebaseFirestore.instance.collection('foods').add({
                              ...payload,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        } catch (e) {
                          _showMessage(context, 'Save failed: $e');
                          setLocal(() => saving = false);
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('foods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final foods = snapshot.data!.docs;
          final categoryOptions = foods
              .map((doc) => (doc.data()['category'] as String? ?? '').trim())
              .where((cat) => cat.isNotEmpty)
              .toSet()
              .toList();
          if (foods.isEmpty) {
            return Stack(
              children: [
                const Center(child: Text('No foods yet. Add your first item.')),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    backgroundColor: AppColor.orange,
                    onPressed: () => _openFoodDialog(
                      context,
                      categoryOptions: categoryOptions,
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              ListView.builder(
                itemCount: foods.length,
                itemBuilder: (context, index) {
                  final doc = foods[index];
                  final data = doc.data();
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: (data['imageUrl'] as String? ?? '').isEmpty
                          ? const Icon(Icons.fastfood)
                          : Image.network(
                              data['imageUrl'] as String,
                              width: 48,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                      title: Text(
                        '${data['name'] ?? ''} (${AppFormatters.bdt(((data['price'] as num?) ?? 0).toDouble())})',
                      ),
                      subtitle: Text(
                        '${data['category'] ?? 'General'} | ${((data['available'] as bool?) ?? true) ? 'Available' : 'Hidden'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openFoodDialog(
                              context,
                              existing: doc,
                              categoryOptions: categoryOptions,
                            ),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('foods').doc(doc.id).delete();
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  backgroundColor: AppColor.orange,
                  onPressed: () => _openFoodDialog(
                    context,
                    categoryOptions: categoryOptions,
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderManagementTab extends StatelessWidget {
  const _OrderManagementTab();

  static const List<String> _statuses = [
    'pending',
    'accepted',
    'preparing',
    'on_the_way',
    'delivered',
    'cancelled',
  ];

  Future<void> _updateOrderStatus(DocumentSnapshot<Map<String, dynamic>> doc, String newValue) async {
    final data = doc.data() ?? {};
    final userId = data['userId'] as String?;
    await FirebaseFirestore.instance.collection('orders').doc(doc.id).set({
      'status': newValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (userId != null && userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('inbox').add({
        'title': 'Order Status Updated',
        'body': 'Your order ${doc.id.substring(0, 6)} is now ${newValue.replaceAll('_', ' ')}.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final data = doc.data();
            final status = (data['status'] as String?) ?? 'pending';
            final total = ((data['total'] as num?) ?? 0).toDouble();
            final userEmail = (data['userEmail'] as String?) ?? 'Unknown';
            final items = (data['items'] as List<dynamic>? ?? [])
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ExpansionTile(
                title: Text('Order ${doc.id.substring(0, 6)} - ${AppFormatters.bdt(total)}'),
                subtitle: Text('User: $userEmail'),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Row(
                    children: [
                      const Text('Status: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _statuses.contains(status) ? status : 'pending',
                        items: _statuses
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (newValue) async {
                          if (newValue == null) return;
                          await _updateOrderStatus(doc, newValue);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Address: ${(data['address'] as String?) ?? '-'}'),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...items.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['name']?.toString() ?? ''),
                      subtitle: Text(AppFormatters.bdt(((item['price'] as num?) ?? 0).toDouble())),
                      trailing: Text('x${item['quantity']}'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

