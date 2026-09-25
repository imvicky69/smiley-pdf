# Smiley PDF — Release Notes

## Version 1.0.0 (Build 1)
*Release Date: September 25, 2026*  
*Package Name: `in.xweet.smileypdf`*

---

### 🎉 Welcome to Smiley PDF v1.0.0!

**Smiley PDF** is a modern, joyful, fast, and privacy-first PDF reader and document manager designed specifically for Android. With a vibrant yet clean aesthetic, zero intrusive permissions, and instantaneous loading, Smiley PDF makes managing and reading documents delightful.

---

### ✨ Key Features & Highlights

#### 📄 High-Performance PDF Viewer
- **Instant Rendering**: Hardware-accelerated, high-fidelity PDF rendering with fluid pan and pinch-to-zoom gestures.
- **In-Place Rename**: Tap the document title in the top bar to inspect metadata and rename documents directly on storage.
- **Document Metadata Modal**: View exact file size, total page count, last modified date & time, and full storage location.
- **1-Tap Save / Unsave**: Instant bookmark toggle directly saves the PDF into your offline app library or unsaves it with a lightweight toast (no tedious confirmation dialogs).
- **Native Share Dialog**: Easily share open documents directly to WhatsApp, Gmail, Drive, or any installed app via Android's native share sheet.

#### 🏠 Joyful Home Screen & Recents Management
- **Recently Viewed Documents**: Clean list showing the top 10 most recent files with real page thumbnails, file size, and last opened indicators.
- **iOS-Style Swipe-to-Remove**: Smoothly slide left on any recent document card to dismiss it from history with an instant **Undo** option.
- **Automatic Missing File Purge**: Deleted or missing documents are automatically detected and cleanly purged from recent history without ugly error badges.
- **Older PDFs & Archive Access**: When you have more than 10 recents, tap the **"View Older PDFs & Archive"** card or **"View all"** to browse your full reading history.
- **Quick Tools Grid**: Modern shortcuts for OCR Text, Scan Document, and Protect PDF utilities.

#### 🔍 Dedicated Full Recents Screen (`AllRecentsScreen`)
- Real-time search across all opened PDFs.
- Slide-left-to-remove gesture support on every item.
- "Clear all" action with safety confirmation.

#### 📚 Dedicated Offline Library
- **Sandbox App Storage**: Dedicated space for your permanently saved documents, available 100% offline.
- **Duplicate Prevention**: Intelligently prevents duplicate file saves based on file path, hash, and content size.
- **Clean UI**: Minimalist top bar with a search input and live document counter badge. No bulky category buttons or permission nagging.
- **Built-in Welcome Guide**: Preloaded with a friendly "Welcome to Smiley PDF" guide for new users with restore capabilities.
- **Document Actions**: Open, share, rename, and delete saved files with ease.

#### 🔒 Privacy & Google Play Store Compliance
- **Zero Sensitive Permissions**: No `MANAGE_EXTERNAL_STORAGE` or dangerous file access permissions requested. Smiley PDF is 100% compliant with Google Play Store policies.
- **Offline & Private**: All document operations stay strictly on your device. Zero analytics, zero data collection.
- **System Intent Support**: Seamlessly opens files via Android's "Open With" dialog and incoming share actions.

---

### 📦 Split APK Distribution

To minimize download size and memory footprint, release builds are generated as ABI-specific split APKs:

| Architecture | Target Devices | APK Name |
| :--- | :--- | :--- |
| **arm64-v8a** | Modern Android phones & tablets (64-bit) | `app-arm64-v8a-release.apk` |
| **armeabi-v7a** | Legacy Android devices (32-bit) | `app-armeabi-v7a-release.apk` |
| **x86_64** | Chromebooks, emulators & x86 devices | `app-x86_64-release.apk` |

---

### 🛠️ Technical Details
- **Framework**: Flutter (Dart 3.x)
- **Engine**: pdfrx (PDFium Native)
- **Min SDK**: Android 21 (Lollipop)
- **Target SDK**: Android 34 / 35 (Latest Android)
- **Package Identifier**: `in.xweet.smileypdf`
