# Smiley PDF 😄📄

A modern, fast, clean, and joyful PDF reader and document manager built for Android using Flutter.

## 🚀 Features & Architecture

This repository comes clean and ready to code without default template bloat or counter code:
- **Clean Architecture Ready**: Structured with feature-first separation (`core`, `features`).
- **Material 3 Theming**: Pre-configured Light & Dark themes with customized palettes in [`app_theme.dart`](lib/core/theme/app_theme.dart).
- **Responsive & Modern UI**: Sleek, friendly interface with animated transitions and theme toggling.
- **Android Optimized**: Android namespace configured (`com.smileypdf.smiley_pdf`), app label set to "Smiley PDF".

---

## 📁 Project Structure

```text
smiley_pdf/
├── android/                   # Native Android configuration & build scripts
├── assets/                    # Project asset directories
│   ├── documents/             # Sample PDF documents
│   ├── icons/                 # Custom app & action icons
│   └── images/                # Graphic assets & illustrations
├── lib/
│   ├── core/                  # Core constants, utilities, and theme
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       └── app_theme.dart
│   ├── features/              # Feature modules
│   │   └── home/
│   │       └── presentation/
│   │           └── screens/
│   │               └── home_screen.dart
│   ├── app.dart               # SmileyPdfApp MaterialApp configuration
│   └── main.dart              # Application entry point
├── test/
│   └── widget_test.dart       # Widget test suite
└── pubspec.yaml               # Project dependencies and asset registry
```

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (3.12+ recommended)
- Android Studio / Android SDK
- An Android device or emulator

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

### 3. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

---

## 💡 Next Steps for Coding

When you're ready to integrate PDF viewing or file picking:
1. **File Picking**: Add [`file_picker`](https://pub.dev/packages/file_picker) to select PDFs from device storage.
2. **PDF Viewer**: Add [`flutter_pdfview`](https://pub.dev/packages/flutter_pdfview) or [`pdfx`](https://pub.dev/packages/pdfx) to render documents with smooth zoom & navigation.
3. **State Management**: Connect your preferred state management (Riverpod, Bloc, Provider) in `lib/features/`.
