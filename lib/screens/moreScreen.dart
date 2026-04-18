import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fooder/const/colors.dart';
import 'package:fooder/screens/aboutScreen.dart';
import 'package:fooder/screens/inboxScreen.dart';
import 'package:fooder/screens/myOrderScreen.dart';
import 'package:fooder/screens/notificationScreen.dart';
import 'package:fooder/screens/paymentScreen.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class MoreScreen extends StatelessWidget {
  static const routeName = '/moreScreen';

  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
children: [
          SafeArea(
            child: Container(
              height: Helper.getScreenHeight(context),
              width: Helper.getScreenWidth(context),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('More', style: Helper.getTheme(context).headline5),
                        const Icon(Icons.shopping_bag_outlined),
                      ],
                    ),
                    const SizedBox(height: 20),
                    MoreCard(
                      image: Image.asset(Helper.getAssetName('income.png', 'virtual')),
                      name: 'Payment Details',
                      handler: () => Navigator.of(context).pushNamed(PaymentScreen.routeName),
                    ),
                    const SizedBox(height: 10),
                    MoreCard(
                      image: Image.asset(Helper.getAssetName('shopping_bag.png', 'virtual')),
                      name: 'My Orders',
                      handler: () => Navigator.of(context).pushNamed(MyOrderScreen.routeName),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: uid == null
                          ? null
                          : FirebaseFirestore.instance
                              .collection('orders')
                              .where('userId', isEqualTo: uid)
                              .where('status', whereIn: ['pending', 'accepted', 'preparing', 'on_the_way'])
                              .snapshots(),
                      builder: (context, snapshot) {
                        final activeCount = snapshot.data?.size ?? 0;
                        return MoreCard(
                          image: Image.asset(Helper.getAssetName('noti.png', 'virtual')),
                          name: 'Notifications',
                          badgeCount: activeCount,
                          handler: () => Navigator.of(context).pushNamed(NotificationScreen.routeName),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: uid == null
                          ? null
                          : FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('inbox')
                              .where('read', isEqualTo: false)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final unread = snapshot.data?.size ?? 0;
                        return MoreCard(
                          image: Image.asset(Helper.getAssetName('mail.png', 'virtual')),
                          name: 'Inbox',
                          badgeCount: unread,
                          handler: () => Navigator.of(context).pushNamed(InboxScreen.routeName),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    MoreCard(
                      image: Image.asset(Helper.getAssetName('info.png', 'virtual')),
                      name: 'About Us',
                      handler: () => Navigator.of(context).pushNamed(AboutScreen.routeName),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar(more: true)),
        ],
      ),
    );
  }
}

class MoreCard extends StatelessWidget {
  const MoreCard({
    super.key,
    required this.name,
    required this.image,
    required this.handler,
    this.badgeCount = 0,
  });

  final String name;
  final Image image;
  final VoidCallback handler;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handler,
      child: SizedBox(
        height: 70,
        width: double.infinity,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                color: AppColor.placeholderBg,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const ShapeDecoration(shape: CircleBorder(), color: AppColor.placeholder),
                    child: image,
                  ),
                  const SizedBox(width: 10),
                  Text(name, style: const TextStyle(color: AppColor.primary)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: 30,
                width: 30,
                decoration: const ShapeDecoration(shape: CircleBorder(), color: AppColor.placeholderBg),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColor.secondary, size: 17),
              ),
            ),
            if (badgeCount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 20,
                  width: 20,
                  margin: const EdgeInsets.only(right: 50),
                  decoration: const ShapeDecoration(shape: CircleBorder(), color: Colors.red),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



