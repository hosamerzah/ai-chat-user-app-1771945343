# AI Chat User App - Deployment Guide

This guide provides instructions for setting up your Firebase project and deploying the AI Chat User Application.

## 1. Firebase Project Setup

Before deploying the Flutter application, you need to set up a Firebase project.

### 1.1 Create a Firebase Project

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Click "Add project" and follow the on-screen instructions to create a new project.

### 1.2 Register Your App with Firebase

Depending on your target platform (Web, Android, iOS), you need to register your app:

-   **For Web**: Add a web app to your Firebase project. Follow the instructions to get your Firebase configuration object. You will need to add this to your Flutter project.
-   **For Android**: Add an Android app to your Firebase project. Download the `google-services.json` file and place it in `android/app/` directory of your Flutter project.
-   **For iOS**: Add an iOS app to your Firebase project. Download the `GoogleService-Info.plist` file and place it in `ios/Runner/` directory of your Flutter project.

### 1.3 Enable Firebase Services

In your Firebase project console, enable the following services:

-   **Authentication**: Go to "Authentication" -> "Sign-in method" and enable "Email/Password".
-   **Firestore Database**: Go to "Firestore Database" and create a new database. Choose a starting mode (e.g., "Start in production mode" and set up security rules later).
-   **Cloud Storage**: Go to "Storage" and set up a new bucket.

### 1.4 Configure Firebase Security Rules

It is crucial to set up appropriate security rules for Firestore and Storage to protect your data. Refer to the `SECURITY.md` file in the project for conceptual security rules. You will need to adapt these to your specific needs.

**Example Firestore Rules (for `ai_chat_user_app`):**

```firestore
rules
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update, delete: if request.auth.uid == userId;
      allow create: if request.auth.uid != null;
    }

    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth.uid != null && (resource.data.senderId == request.auth.uid || resource.data.receiverId == request.auth.uid);
    }

    match /characters/{characterId} {
      allow read: if request.auth.uid != null;
      // Admins (from admin app) will have write access, users only read
      allow write: if false; // User app should not write to characters
    }

    match /ad_campaigns/{adId} {
      allow read: if request.auth.uid != null;
      // Admins (from admin app) will have write access, users only read
      allow write: if false; // User app should not write to ad_campaigns
    }

    match /payment_methods/{paymentMethodId} {
      allow read: if request.auth.uid != null;
      // Admins (from admin app) will have write access, users only read
      allow write: if false; // User app should not write to payment_methods
    }
  }
}
```

## 2. Flutter Project Configuration

### 2.1 Add Firebase Configuration to Flutter

-   **For Web**: In `web/index.html`, add your Firebase configuration object within the `<head>` tags.
-   **For Android/iOS**: The `google-services.json` and `GoogleService-Info.plist` files handle the configuration automatically.

### 2.2 Install Firebase CLI

If you haven't already, install the Firebase CLI:

```bash
npm install -g firebase-tools
```

Log in to Firebase:

```bash
firebase login
```

### 2.3 Configure FlutterFire

From your Flutter project directory, configure FlutterFire for your project:

```bash
flutterfire configure
```

Follow the prompts to select your Firebase project and the platforms you want to configure.

## 3. Building and Deploying the Application

### 3.1 Build for Web

To build the web version of your application, navigate to your project directory and run:

```bash
flutter build web --release
```

This will generate a `build/web` directory containing your web application.

### 3.2 Deploy to Firebase Hosting

1.  Initialize Firebase Hosting in your project directory:
    ```bash
    firebase init hosting
    ```
    -   Select your Firebase project.
    -   For "What do you want to use as your public directory?", enter `build/web`.
    -   Configure as a single-page app (rewrite all URLs to `/index.html`).

2.  Deploy your web application:
    ```bash
    firebase deploy --only hosting
    ```

### 3.3 Build for Android (Optional)

To build an Android App Bundle (for Google Play Store) or an APK:

```bash
flutter build appbundle --release
# Or for an APK:
flutter build apk --release
```

### 3.4 Build for iOS (Optional)

To build an iOS app (requires a Mac and Xcode):

```bash
flutter build ios --release
```

Open the `ios/Runner.xcworkspace` in Xcode to manage signing and deployment to the App Store.

## 4. Multi-Theme Deployment (Separate Apps)

If you intend to deploy separate applications with different themes (e.g., Brand A app, Brand B app), you will need to:

1.  Create separate Flutter projects (as done during refactoring).
2.  In each project, modify `lib/main.dart` to set the `ThemeProvider`'s initial theme to the desired brand theme.
3.  Build and deploy each project independently to its own hosting environment or app store listing.

This guide should help you successfully deploy your AI Chat User App. For any issues, refer to the official Flutter and Firebase documentation.
