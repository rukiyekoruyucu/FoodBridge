<h1 align="center">FoodBridge 🍲</h1>

<p align="center">
  <strong>A modern, community-driven platform to reduce food waste and connect people.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Riverpod-000000?style=for-the-badge&logo=dart&logoColor=white" alt="Riverpod" />
</p>

---

## 📱 About The Project

**FoodBridge** is an innovative social responsibility application designed to eliminate food waste by connecting individuals, businesses, and people in need. The platform allows users to share surplus food, track nearby donations in real-time, and securely chat to coordinate pickups.

This project was built from the ground up as a **Full-Stack Mobile Application** prioritizing performance, security, and a premium User Experience (UX).

### ✨ Key Features

- **Real-Time Live Feed**: Browse available food donations instantly.
- **Interactive Map Integration**: Find "Public Fridges" and nearby items using geolocation.
- **Secure Chat System**: Coordinate pickups privately via encrypted socket connections.
- **Role-Based Ecosystem**: Specialized interfaces for Personal users, Corporate donors, and people in Need.
- **Modern UI/UX**: Shimmer loading effects, Glassmorphism design elements, and Material 3 guidelines.

---

## 📸 Screenshots

*(Replace these placeholder links with your actual screenshot images once you take them on your phone!)*

<p align="center">
  <img src="screenshots/login.png" width="200" alt="Login Screen" />
  <img src="screenshots/home.png" width="200" alt="Home Screen" />
  <img src="screenshots/map.png" width="200" alt="Map Screen" />
  <img src="screenshots/chat.png" width="200" alt="Chat Screen" />
</p>

---

## 🛠️ Tech Stack & Architecture

### Frontend (Mobile App)
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: GoRouter (Declarative Routing)
- **Design System**: Material 3 + Google Fonts + Custom Glassmorphism Widgets
- **API Communication**: Dio & Http for REST APIs

### Backend (API Server)
- **Runtime**: Node.js & Express.js
- **Database**: SQLite (Migrated from PostgreSQL for high-speed local WAL operations)
- **Authentication**: Firebase Auth Admin SDK (JWT Validation)
- **Real-time**: Socket.io (For live chat and notifications)
- **Storage**: Cloudinary (For optimized image delivery)
- **Deployment**: CI/CD via Railway.app

---

## 🚀 How to Run Locally

If you want to compile and run this project on your own machine:

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- An Android Emulator or physical device connected.

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/rukiyekoruyucu/FoodBridge-App.git
   ```
2. Navigate to the project directory:
   ```bash
   cd FoodBridge-App
   ```
3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```
*Note: The app is pre-configured to connect to the live production backend hosted on Railway. No local backend setup is required to test the mobile app!*

---

## 🧠 Engineering Decisions & Challenges Overcome

- **Database Migration (PostgreSQL -> SQLite)**: To reduce cloud dependency and ensure a self-contained, lightning-fast backend, the entire schema was rewritten for SQLite using the `better-sqlite3` library with WAL (Write-Ahead Logging) mode enabled for concurrency.
- **Navigation Modernization**: Transitioned from legacy `Navigator 1.0` to `GoRouter` for robust deep-linking and stateful nested navigation (ShellRoute).
- **State Management**: Upgraded to strongly-typed Riverpod providers, eliminating `setState` memory leaks and ensuring a reactive UI layer.

---

<p align="center">
  <i>Designed and Developed by <a href="https://github.com/rukiyekoruyucu">Rukiye Koruyucu</a></i>
</p>
