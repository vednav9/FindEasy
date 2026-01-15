# 📱 FindEasy - Service Booking & Utility App

**FindEasy** is a robust cross-platform mobile application built with **Flutter** and **Firebase**. It connects customers with local service providers, allowing users to discover services, view locations via Google Maps, and manage bookings seamlessly.

---

## 🌟 Key Features

### ✅ For Customers
- **Secure Authentication:** Easy login and registration.
- **Service Discovery:** Browse categories and find local providers.
- **Interactive Maps:** View provider locations on Google Maps.
- **Booking Management:** Book services, view history, and track status.
- **Special Offers:** Access exclusive discounts and promotions.

### ✅ For Providers
- **Business Dashboard:** View analytics and performance metrics.
- **Booking Requests:** Accept or reject incoming service requests.
- **Service Management:** Add, update, or remove service listings.
- **Profile Management:** Edit business details and availability.

---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Firestore, Cloud Functions)
- **Maps:** Google Maps SDK
- **Architecture:** MVC (Model-View-Controller) Pattern

---

## 🚀 How to Run the Project

Since this project uses secure API keys that are not uploaded to GitHub, follow these steps to set up the environment locally.

### ✅ 1. Prerequisites
Ensure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [VS Code](https://code.visualstudio.com/) or Android Studio
- An Android Emulator or Physical Device

### ✅ 2. Clone the Repository

```bash
git clone https://github.com/Varun311004/FindEasy.git
cd FindEasy
```

### ✅ 3. Install Dependencies
Download the required Flutter packages:

```bash
flutter pub get
```

### ✅ 4. 🔐 Security Configuration (Crucial Step)
This project requires local configuration files for Google Maps and Firebase to run.

#### Step A: Configure Google Maps (Android)
1. Navigate to the `android/` folder.
2. Create a new file named `local.properties` (if it doesn't exist).
3. Paste the following code (replace with your actual paths and key):

```properties
sdk.dir=/path/to/your/android/sdk
flutter.sdk=/path/to/your/flutter/sdk
google.maps.key=YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE
```

**Note:** The app reads this key automatically during build.

#### Step B: Configure Firebase
1. Go to your Firebase Console.
2. Download the `google-services.json` file for Android.
3. Place it inside the `android/app/` folder.
4. (Optional for iOS) Download `GoogleService-Info.plist` and place it inside `ios/Runner/`.

### ✅ 5. Run the App
Once configuration is complete, run the app:

```bash
flutter run
```

---

## 📂 Project Structure
A quick look at the top-level directory structure:

```
lib/
├── models/          # Data models (Category, Provider, Review)
├── pages/           # UI Screens
│   ├── Customer/    # Customer screens (Home, Booking, Profile, Search)
│   └── Provider/    # Provider screens (Analytics, Services, Bookings)
├── services/        # Authentication and Backend logic
├── widgets/         # Reusable UI components
└── main.dart        # Application Entry Point
```

---

## 📝 Notes for Developers
- **Ignored Files:** The `token/` folder and sensitive JSON keys (e.g., `service_account.json`) are intentionally ignored via `.gitignore` and `.git/info/exclude`.

- **Linting:** The project uses `analysis_options.yaml` to ensure code quality.

---

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Commit your Changes
   ```bash
   git commit -m "Add some AmazingFeature"
   ```
4. Push to the Branch
   ```bash
   git push origin feature/AmazingFeature
   ```
5. Open a Pull Request

---

## 👨‍💻 Developed By
Varun Kiran Joshi
