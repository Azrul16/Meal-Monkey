# Meal Monkey

Meal Monkey is a Flutter food-ordering application with Firebase authentication, Firestore-backed food, cart, order, profile, payment, and inbox data, plus an admin panel for managing the menu and customer orders.

The project is built as a multi-platform Flutter app, with the current Firebase configuration focused on Android.

## Features

- User onboarding with splash, landing, login, signup, forgot-password, OTP, and new-password screens.
- Firebase email/password authentication for customer accounts.
- Admin login through environment variables for a dedicated management dashboard.
- Firestore-powered home feed with available foods, category chips, search, sorting, popular items, and item detail pages.
- Cart management with quantity updates and item removal.
- Checkout flow with delivery address, cash-on-delivery payment, order summary, and order confirmation.
- Order tracking through user cart/order screens and admin status updates.
- Admin dashboard with food metrics, order metrics, active orders, and gross sales.
- Admin food management for adding, editing, hiding, deleting, and previewing menu items.
- Admin order management with status updates and automatic user inbox notifications.
- User profile management, saved payment methods, inbox messages, notifications, offers, about, and more screens.
- Custom Metropolis font family and bundled image assets.

## Tech Stack

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- flutter_dotenv
- flutter_launcher_icons

## Project Structure

```text
lib/
  const/                 App color constants
  screens/               Application screens and flows
  utils/                 Formatting and UI helper utilities
  widgets/               Reusable UI widgets
  firebase_options.dart  Firebase configuration loader
  main.dart              App entry point, routes, theme, Firebase bootstrap

assets/
  fonts/                 Metropolis font files
  images/real/           Real image assets
  images/virtual/        UI and brand assets

android/ ios/ web/
linux/ macos/ windows/   Flutter platform shells
```

## Firebase Data Model

The app expects these Firestore collections and subcollections:

```text
foods/{foodId}
  name: string
  category: string
  price: number
  currency: string
  rating: number
  discountPercent: number
  imageUrl: string
  description: string
  available: boolean
  createdAt: timestamp
  updatedAt: timestamp

users/{uid}
  name: string
  email: string
  phone: string
  addressLine1: string
  addressLine2: string
  address: string
  gender: string
  dateOfBirth: string
  occupation: string
  isAdmin: boolean
  createdAt: timestamp
  updatedAt: timestamp

users/{uid}/cart/{cartItemId}
users/{uid}/payment_methods/{methodId}
users/{uid}/inbox/{messageId}

orders/{orderId}
  userId: string
  userEmail: string
  address: string
  status: pending | accepted | preparing | on_the_way | delivered | cancelled
  subtotal: number
  deliveryCost: number
  total: number
  currency: string
  paymentMethod: string
  items: array
  createdAt: timestamp
  updatedAt: timestamp
```

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart SDK `^3.11.4`
- Android Studio or VS Code with Flutter tooling
- A Firebase project with Authentication and Cloud Firestore enabled
- FlutterFire CLI if you need to regenerate Firebase configuration

### Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd Meal-Monkey
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the project root:

   ```env
   FIREBASE_API_KEY=your_firebase_api_key
   FIREBASE_APP_ID=your_android_firebase_app_id
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_storage_bucket

   ADMIN_USERNAME=admin@example.com
   ADMIN_PASSWORD=strong_admin_password
   ```

4. Confirm Firebase is configured for your target platform.

   The included `firebase_options.dart` currently provides Android options from `.env`. For iOS, web, macOS, Windows, or Linux, regenerate the Firebase options:

   ```bash
   flutterfire configure
   ```

5. Run the app:

   ```bash
   flutter run
   ```

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk
flutter pub run flutter_launcher_icons
```

## Admin Access

The admin panel is opened from the login screen when the entered username and password match:

```env
ADMIN_USERNAME=...
ADMIN_PASSWORD=...
```

Admin users can view dashboard metrics, manage foods, and update order statuses. When an order status changes, the app writes a notification into the customer's `users/{uid}/inbox` collection.

## Notes

- Social login buttons are present in the UI, but Facebook and Google login are not configured yet.
- Checkout currently uses cash on delivery.
- Prices are formatted in BDT.
- The app includes platform folders for multiple Flutter targets, but Firebase options are only prepared for Android unless regenerated.

## License

No license file is currently included. Add a license before publishing or distributing this project.
