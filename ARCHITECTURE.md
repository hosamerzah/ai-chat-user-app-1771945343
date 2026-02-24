# AI Chat User App Architecture

This document outlines the architecture of the AI Chat User Application, focusing on its Flutter-based frontend, Firebase backend integration, multi-theme support, and localization capabilities.

## 1. Overview

The AI Chat User App is a Flutter application designed to provide an interactive chat experience with AI characters. It supports multiple themes for branding and offers robust localization for a global user base, starting with Arabic and English. The backend services are powered by Firebase, ensuring scalability, real-time data synchronization, and secure user management.

## 2. Technology Stack

-   **Frontend**: Flutter (Dart)
-   **Backend**: Firebase (Authentication, Firestore, Storage)
-   **State Management**: Provider
-   **Localization**: Flutter's built-in internationalization (using `.arb` files and `flutter_localizations`)
-   **Theming**: Custom theme definitions and `ChangeNotifier` for dynamic theme switching

## 3. Core Architectural Components

### 3.1. Presentation Layer (Flutter UI)

This layer is responsible for rendering the user interface and handling user interactions. It consists of:

-   **Screens**: Individual pages of the application (e.g., `LoginScreen`, `HomeScreen`, `ChatScreen`).
-   **Widgets**: Reusable UI components that compose the screens.
-   **Themes**: Defined in `lib/themes/` (e.g., `light_theme.dart`, `dark_theme.dart`, `brand_a_theme.dart`, `brand_b_theme.dart`). These provide distinct visual styles that can be switched dynamically.
-   **Localization**: Handled via `.arb` files in `lib/l10n/` and generated Dart classes (`app_localizations.dart`). This enables the app to support multiple languages, including Right-to-Left (RTL) layouts for Arabic.

### 3.2. Application Layer (Providers)

This layer manages the application's state and business logic, making it accessible to the UI layer. Key providers include:

-   **`ThemeProvider`**: Manages the current theme of the application, allowing for dynamic switching between defined themes.
-   **`LocaleProvider`**: Manages the current language (locale) of the application, enabling users to switch between supported languages.

### 3.3. Data Layer (Firebase Service)

The data layer abstracts the interaction with the Firebase backend. The `FirebaseService` (`lib/services/firebase_service.dart`) acts as a single point of contact for all Firebase operations, including:

-   **Authentication**: User sign-in, sign-up, and sign-out using `FirebaseAuth`.
-   **Firestore**: Real-time database operations for storing and retrieving chat messages, user data, character information, active advertisements, and payment methods.
-   **Cloud Storage**: Handling file uploads (e.g., for ad images) using `FirebaseStorage`.

## 4. Data Flow

1.  **User Interaction**: Users interact with the UI (e.g., typing a message, switching a theme).
2.  **UI Events**: UI components trigger events that are handled by screens or widgets.
3.  **Provider Interaction**: Screens or widgets interact with `ThemeProvider` or `LocaleProvider` to update UI state, or with `FirebaseService` to perform backend operations.
4.  **Firebase Operations**: `FirebaseService` communicates with Firebase services (Auth, Firestore, Storage).
5.  **Data Synchronization**: Firebase (Firestore) provides real-time data updates, which are streamed back to the UI via `StreamBuilder` widgets.
6.  **UI Update**: Providers notify their listeners (UI widgets) of state changes, causing the UI to rebuild with the new data or theme/locale settings.

## 5. Multi-Theme and Localization Strategy

### 5.1. Multi-Theme

-   **Theme Definitions**: Each theme (light, dark, brand A, brand B) is defined as a `ThemeData` object in its own `.dart` file within `lib/themes/`.
-   **`ThemeProvider`**: A `ChangeNotifier` that holds the currently active `ThemeData` and provides methods to switch between themes. The `MaterialApp` consumes this provider to apply the selected theme.
-   **Dynamic Switching**: Users can switch themes from the UI, and the change is immediately reflected across the application.

### 5.2. Localization

-   **`.arb` Files**: Language-specific strings are stored in Application Resource Bundle (`.arb`) files (e.g., `app_en.arb`, `app_ar.arb`) in `lib/l10n/`.
-   **`l10n.yaml`**: Configuration file that tells Flutter's internationalization tool where to find `.arb` files and how to generate the localization delegate.
-   **`AppLocalizations`**: Generated class that provides access to localized strings. Widgets use `AppLocalizations.of(context)` to retrieve strings based on the current locale.
-   **`LocaleProvider`**: A `ChangeNotifier` that manages the current `Locale` of the application, allowing users to switch languages. The `MaterialApp` consumes this provider to apply the selected locale.
-   **RTL Support**: Flutter automatically handles Right-to-Left (RTL) layouts for languages like Arabic when the locale is set correctly.

## 6. Firebase Data Model (User App Relevant Collections)

-   **`users/{uid}`**: Stores user-specific data, including `tokenBalance` and `role`.
-   **`chats/{chatId}/messages`**: Subcollection storing individual chat messages between a user and a character.
-   **`characters`**: Top-level collection storing AI character definitions (read-only for user app).
-   **`ad_campaigns`**: Top-level collection storing advertisement details (read-only for user app, filtered by active dates).
-   **`payment_methods`**: Top-level collection storing available payment methods (read-only for user app).

## 7. Future Considerations

-   **Offline Support**: Implement caching mechanisms for offline access to chat history and character data.
-   **Advanced State Management**: For more complex applications, consider more powerful state management solutions like Riverpod or Bloc.
-   **Testing**: Expand unit, widget, and integration tests for all layers of the application.
-   **Performance Optimization**: Optimize UI rendering and data fetching for large datasets.
-   **Security Rules**: Refine Firestore security rules to ensure robust data protection and access control.

This architecture provides a solid foundation for the AI Chat User App, allowing for maintainability, scalability, and extensibility. It separates concerns effectively, making it easier to develop, test, and deploy new features.
