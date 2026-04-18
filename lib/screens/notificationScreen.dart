import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class NotificationScreen extends StatelessWidget {
  static const routeName = '/notiScreen';

  const NotificationScreen({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                      ),
                      Expanded(child: Text('Notifications', style: Helper.getTheme(context).headline5)),
                      const Icon(Icons.shopping_bag_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: uid == null
                      ? const Center(child: Text('Please login first.'))
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .where('userId', isEqualTo: uid)
                              .orderBy('updatedAt', descending: true)
                              .limit(30)
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
                              return const Center(child: Text('No notifications yet.'));
                            }

                            return ListView.builder(
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final data = orders[index].data();
                                final status = (data['status'] as String? ?? 'pending').replaceAll('_', ' ');
                                final updatedAt = data['updatedAt'] as Timestamp?;
                                return NotiCard(
                                  title: 'Order ${orders[index].id.substring(0, 6)} is $status',
                                  time: _formatTime(updatedAt),
                                  color: index.isEven ? Colors.white : AppColor.placeholderBg,
                                );
                              },
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

class NotiCard extends StatelessWidget {
  const NotiCard({
    super.key,
    required this.time,
    required this.title,
    this.color = Colors.white,
  });

  final String time;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(color: AppColor.placeholder, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(backgroundColor: AppColor.orange, radius: 5),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColor.primary)),
                const SizedBox(height: 2),
                Text(time),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



