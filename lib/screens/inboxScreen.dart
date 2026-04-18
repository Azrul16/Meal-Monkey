import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fooder/const/colors.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class InboxScreen extends StatelessWidget {
  static const routeName = '/inboxScreen';

  const InboxScreen({super.key});

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
                      Expanded(child: Text('Inbox', style: Helper.getTheme(context).headline5)),
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
                              .collection('users')
                              .doc(uid)
                              .collection('inbox')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final messages = snapshot.data!.docs;
                            if (messages.isEmpty) {
                              return const Center(
                                child: Text('No inbox messages yet.'),
                              );
                            }

                            return ListView.builder(
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final data = messages[index].data();
                                final title = (data['title'] as String? ?? 'Meal Monkey Update').trim();
                                final body = (data['body'] as String? ?? '').trim();
                                final ts = data['createdAt'] as Timestamp?;
                                final dt = ts?.toDate();
                                final time = dt == null
                                    ? 'Now'
                                    : '${dt.day}/${dt.month}/${dt.year}';
                                return MailCard(
                                  title: title,
                                  description: body.isEmpty ? 'No details provided.' : body,
                                  time: time,
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

class MailCard extends StatelessWidget {
  const MailCard({
    super.key,
    required this.time,
    required this.title,
    required this.description,
    this.color = Colors.white,
  });

  final String time;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: Border(bottom: BorderSide(color: AppColor.placeholder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(backgroundColor: AppColor.orange, radius: 5),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColor.primary)),
                const SizedBox(height: 4),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(time, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}



