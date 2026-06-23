# Studyco. Education App 📚

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black)
![GetX](https://img.shields.io/badge/GetX-State_Management-purple?style=for-the-badge)

Studyco is a modern, feature-rich educational platform built with Flutter. It provides students with seamless access to study materials, secure offline downloads, a streamlined cart & payment system, and an interactive profile management experience.

## ✨ Key Features

### 🔐 Authentication & Security
- **Single Sign-On (SSO):** Seamless and secure Google Sign-In integration.
- **Firebase Authentication:** Handles user sessions reliably.
- **Secure Screenshot Prevention:** Protects premium study materials using the `no_screenshot` package.

### 🛒 E-Commerce & Payments
- **Cart System:** Add premium materials to a cart and view them globally across the app.
- **Razorpay Integration:** Secure checkout and payment gateway integration using `razorpay_flutter` and `flutter_dotenv` for environment variable management.

### 📄 Content Management
- **Study Materials Explorer:** Grid and List views to browse available subjects and notes.
- **PDF Viewer:** Built-in secure PDF reader (`pdfrx`) to read materials right within the app.
- **Offline Mode:** Download materials locally using `flutter_cache_manager` and access them anytime without the internet.
- **Bookmarks:** Save important materials for quick access later.

### 👤 Profile & User Experience
- **Profile Management:** Edit academic details, contact information, and upload profile pictures directly to Firebase Storage.
- **Push Notifications:** Real-time alerts and engagement through Firebase Cloud Messaging (FCM) and `awesome_notifications`.
- **Skeleton Loaders:** Smooth loading states using `skeletonizer` to improve perceived performance.
- **Pull-to-Refresh:** `liquid_pull_to_refresh` for beautiful, interactive data fetching.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [GetX](https://pub.dev/packages/get)
- **Backend as a Service:** Firebase (Firestore, Auth, Storage, Cloud Functions, Messaging)
- **Local Storage:** `get_storage`, `sqflite`
- **Payment Gateway:** Razorpay

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.0.0 or higher recommended)
- Android Studio / VS Code
- A Firebase Project (for Auth, Firestore, and Storage)
- Razorpay Account (Test or Live credentials)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/MidhlajAm/studyco_app.git
   cd studyco_app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   Create a `.env` file in the root directory and add your Razorpay keys:
   ```env
   RAZORPAY_KEY_ID=your_razorpay_key_id
   RAZORPAY_KEY_SECRET=your_razorpay_key_secret
   ```

4. **Firebase Configuration**
   - Make sure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in their respective directories.
   - Run `flutterfire configure` if necessary to sync your Firebase project.

5. **Run the App**
   ```bash
   flutter run
   ```

---

## 📁 Architecture Overview

This project heavily utilizes the **GetX** ecosystem for routing, dependency injection, and reactive state management (`Rx` observables). 

- `/lib/controllers/`: Contains business logic, state management, and API calls (e.g., `CartController`, `UserProfileController`).
- `/lib/pages/`: Contains the UI screens and widget trees.
- `/lib/models/`: Data classes (e.g., `CartItem`, `MaterialModel`).
- `/lib/bindings/`: GetX bindings to lazily load controllers when navigating to specific routes.
- `/lib/Utilities/`: Shared components, colors, themes, and helper functions.

---

## 📸 Screenshots
*(Add screenshots of your app here to showcase the beautiful UI!)*

<div style="display: flex; flex-direction: row; gap: 10px;">
  <img src="assets/images/placeholder1.png" width="200"/>
  <img src="assets/images/placeholder2.png" width="200"/>
  <img src="assets/images/placeholder3.png" width="200"/>
</div>

---

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! 

## 📝 License
This project is for portfolio purposes. 

---
*Built with ❤️ using Flutter.*
