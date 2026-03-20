<h1 align="center">
  <img src="Pastemac/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="80" alt="PocketPaste icon" /><br/>
  PocketPaste
</h1>

<p align="center">
  A lightweight, open-source macOS clipboard manager that lives quietly in your menu bar.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?logo=apple" />
  <img src="https://img.shields.io/badge/swift-5.9-orange?logo=swift" />
  <img src="https://img.shields.io/badge/license-MIT-blue" />
  <img src="https://img.shields.io/badge/contributions-welcome-brightgreen" />
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 📋 **Clipboard History** | Automatically captures every text, URL, or image you copy |
| 📌 **Pin Items** | Pin important clips — they survive "Clear History" |
| 🔍 **Instant Search** | Filter your history as you type |
| ⌨️ **Keyboard Shortcuts** | Press `⌘1`–`⌘9` to instantly recopy any item |
| ⏸ **Pause / Resume** | Temporarily stop capturing without quitting the app |
| 🗑 **Clear Unpinned** | One-click wipe of regular history, keeping your pins safe |
| 🌗 **Native UI** | Follows macOS light/dark mode automatically |

---

## 📦 Download (Pre-built DMG)

> **Quickest way to get started — no Xcode required.**

1. Download **[PocketPaste.dmg](./PocketPaste.dmg)** from this repository.
2. Open the `.dmg` file.
3. Drag **PocketPaste** into your `/Applications` folder.
4. Launch it — the clipboard icon will appear in your menu bar.

> [!NOTE]
> Because the app is not notarized with an Apple Developer account yet, macOS may show a security warning on first launch.  
> To bypass it: **System Settings → Privacy & Security → Open Anyway**.

---

## 🛠 Build from Source

### Requirements

- macOS 13 Ventura or later
- Xcode 15+ **or** Swift 5.9+ (command-line tools)

### Option 1 — Xcode

```bash
git clone https://github.com/YOUR_USERNAME/PocketPaste.git
cd PocketPaste
open PocketPaste.xcodeproj
```

Select the **PasteMac** scheme and press `⌘R` to build and run.

### Option 2 — Terminal

```bash
git clone https://github.com/YOUR_USERNAME/PocketPaste.git
cd PocketPaste
swift run
```

### Build a Release `.app`

```bash
xcodebuild -project PocketPaste.xcodeproj \
           -scheme PasteMac \
           -configuration Release \
           -derivedDataPath build
```

The built app will be at `build/Build/Products/Release/PasteMac.app`.

---

## 🚀 Create Your Own DMG

```bash
# 1. Build the release app (see above)
# 2. Package it into a DMG
hdiutil create -volname "PocketPaste" \
               -srcfolder build/Build/Products/Release/PasteMac.app \
               -ov -format UDZO \
               PocketPaste.dmg
```

---

## 📁 Project Structure

```
PocketPaste/
├── Pastemac/
│   ├── Sources/PasteMac/
│   │   ├── App/              # App entry point & MenuBarExtra
│   │   ├── Models/           # ClipboardItem, ClipboardStore
│   │   └── Views/            # ContentView, ClipboardRowView
│   └── Assets.xcassets/      # Icons & image assets
├── PocketPaste.xcodeproj/
├── PocketPaste.dmg           # Pre-built installer
└── README.md
```

---

## 🤝 Contributing

**PocketPaste is fully open source and contributions are always welcome!** 🎉

Whether it's a bug fix, new feature, UI improvement, or documentation update — every contribution matters.

### How to Contribute

1. **Fork** this repository
2. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/my-awesome-feature
   ```
3. **Make your changes** and commit with a clear message:
   ```bash
   git commit -m "feat: add iCloud sync for clipboard history"
   ```
4. **Push** to your fork:
   ```bash
   git push origin feature/my-awesome-feature
   ```
5. **Open a Pull Request** — describe what you changed and why.

### Ideas for Contributions

- [ ] iCloud sync across Macs
- [ ] Configurable history limit
- [ ] Rich text / HTML preview
- [ ] Auto-launch at login toggle in the UI
- [ ] Export history to JSON/CSV
- [ ] Localization / translations
- [ ] Notarization & automated CI releases

### Code Style

- Follow Swift API Design Guidelines
- Keep SwiftUI views small and composable
- Add comments for non-obvious logic

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](./LICENSE) for details.  
You are free to use, modify, and distribute this software for any purpose.

---

<p align="center">Made with ❤️ for the macOS community · Open source forever 🔓</p>
