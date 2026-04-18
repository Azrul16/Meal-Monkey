import 'package:flutter/material.dart';
import 'package:fooder/const/colors.dart';
import 'package:fooder/utils/helper.dart';
import 'package:fooder/widgets/customNavBar.dart';

class AboutScreen extends StatelessWidget {
  static const routeName = '/aboutScreen';

  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                      ),
                      Expanded(
                        child: Text('About Us', style: Helper.getTheme(context).headline5),
                      ),
                      const Icon(Icons.shopping_bag_outlined),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _AboutCard(
                    text:
                        'Meal Monkey helps customers across Bangladesh discover food, place orders quickly, and track deliveries in real time.',
                  ),
                  const SizedBox(height: 16),
                  const _AboutCard(
                    text:
                        'Our goal is reliable delivery, transparent pricing in BDT, and a smooth experience for both customers and restaurant admins.',
                  ),
                  const SizedBox(height: 16),
                  const _AboutCard(
                    text:
                        'For business support and partnership, contact your platform admin panel team to manage menu items, offers, and order operations.',
                  ),
                ],
              ),
            ),
          ),
          const Positioned(bottom: 0, left: 0, child: CustomNavBar(menu: true)),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String text;

  const _AboutCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(radius: 5, backgroundColor: AppColor.orange),
        const SizedBox(width: 10),
        Flexible(child: Text(text, style: const TextStyle(color: AppColor.primary))),
      ],
    );
  }
}



