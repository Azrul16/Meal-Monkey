# Fooder

<p align="center">
  <a href="https://github.com/azrul16/fooder/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/azrul16/fooder?style=for-the-badge" /></a>
  <a href="https://github.com/azrul16/fooder/network/members"><img alt="GitHub forks" src="https://img.shields.io/github/forks/azrul16/fooder?style=for-the-badge" /></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" /></a>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
</p>

<p align="center">
  <img src="assets/images/virtual/MealMonkeyLogo.png" alt="Fooder Banner" width="220" />
</p>

<p align="center">
  A Flutter + Firebase food ordering app with customer flow and admin panel management.
</p>

<p align="center">
  <a href="#installation">Installation</a> |
  <a href="#contributing">Contributing</a> |
  <a href="#license">License</a>
</p>

## Overview

Fooder is a multi-screen Flutter application inspired by modern food delivery products.  
It includes:

- Customer authentication and profile management.
- Food browsing with categories, search, offers, and item details.
- Cart, checkout, and order placement flow.
- User notifications and inbox updates.
- Admin panel to manage foods, discounts, and order statuses.

## Features

- Firebase Authentication for user sign-in/sign-up.
- Firestore-backed data model for users, foods, carts, orders, payment methods, and inbox.
- Admin login via environment variables (`ADMIN_USERNAME`, `ADMIN_PASSWORD`).
- Product management tools:
- Add, edit, hide, and delete food items.
- Category-aware item management.
- Discount offer support.
- Order operations:
- Track and update order states (`pending`, `accepted`, `preparing`, `on_the_way`, `delivered`, `cancelled`).
- Customer inbox notifications on status updates.
- Reusable widgets for navigation, search, and inputs.
- BDT currency formatting utility.

## Tech Stack

- Flutter (Dart)
- Firebase Core
- Firebase Auth
- Cloud Firestore
- flutter_dotenv

## Screenshots

> Temporary visuals from current assets. Replace with real app screenshots for production-grade presentation.

| Intro | Home Theme | Login Theme |
|---|---|---|
| <img src="assets/images/virtual/vector1.png" alt="Intro Screen" width="220"/> | <img src="assets/images/virtual/vector2.png" alt="Home Preview" width="220"/> | <img src="assets/images/virtual/login_bg.png" alt="Login Preview" width="220"/> |

## Project Structure

```text
lib/
  const/              # app colors and constants
  screens/            # all user + admin screens
  utils/              # helpers and formatters
  widgets/            # shared UI components
  main.dart           # app entry point and routes
  firebase_options.dart
assets/
  images/
  fonts/
```

## Prerequisites

- Flutter SDK (stable)
- Dart SDK (compatible with Flutter)
- Firebase project (Android configured in current setup)
- Android Studio or VS Code with Flutter extensions

## Installation

1. Clone the repository:

```bash
git clone https://github.com/azrul16/fooder.git
cd fooder
```

2. Install dependencies:

```bash
flutter pub get
```

3. Create environment file:

```bash
cp .env.example .env
```

4. Fill `.env` with real values:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `ADMIN_USERNAME`
- `ADMIN_PASSWORD`

5. Run the app:

```bash
flutter run
```

## Firebase Notes

- Current project configuration includes Firebase options for **Android**.
- If you want iOS/Web/Desktop Firebase support, reconfigure using FlutterFire CLI and update `lib/firebase_options.dart`.

## Scripts and Commands

```bash
flutter analyze
flutter test
flutter run
```

## Contributing

Contributions are welcome and appreciated.

1. Fork this repository.
2. Clone your fork locally.
3. Create a new branch:

```bash
git checkout -b feature/your-feature-name
```

4. Commit your changes:

```bash
git commit -m "feat: add your feature"
```

5. Push and open a Pull Request.

## Support the Project

If this project helped you, please:

- Star this repository.
- Fork it.
- Share it with others.
- Contribute improvements.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

**@azrul16**