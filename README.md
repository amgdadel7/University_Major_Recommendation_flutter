# University Major Recommendation App

A professional Flutter application for academic major recommendations with modern UI/UX, multi-language support, and dark/light themes.

## ✨ Features

### 🎨 Modern Design
- Material Design 3
- Smooth animations and transitions
- Beautiful gradient colors
- Responsive layout for all screen sizes

### 🌐 Multi-Language Support
- **Arabic** (العربية) - Full RTL support
- **English** - LTR layout
- Easy language switching
- Persistent language preferences

### 🌓 Theme Modes
- Light Mode
- Dark Mode
- System Default (Auto)
- Smooth theme transitions
- Persistent theme preferences

### 📱 Core Features

#### Authentication
- Login & Registration
- Email/Password authentication
- Social login options (Google, Apple, Facebook)
- Password recovery

#### Assessment System
- Grade entry and calculation
- Interest survey
- Career goals assessment
- Learning style evaluation

#### Recommendations
- AI-powered major recommendations
- Match percentage calculation
- Detailed major information
- Career opportunities insights

#### Universities
- University search and filtering
- Detailed university profiles
- Available majors listing
- Admission requirements

#### Applications
- Application submission
- Document upload
- Application status tracking
- Multi-step application form

#### Profile
- User profile management
- Academic records
- Settings and preferences
- Notification controls

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── app.dart                 # Main app widget
│   ├── router/
│   │   └── app_router.dart      # Navigation configuration
│   └── theme/
│       ├── app_theme.dart       # Theme definitions
│       ├── app_colors.dart      # Color palette
│       └── bloc/
│           └── theme_bloc.dart  # Theme state management
├── features/
│   ├── auth/                    # Authentication feature
│   ├── home/                    # Home dashboard
│   ├── grades/                  # Grade entry
│   ├── survey/                  # Assessment surveys
│   ├── recommendations/         # Major recommendations
│   ├── universities/            # University browsing
│   ├── applications/            # Application management
│   └── profile/                 # User profile
└── main.dart                    # App entry point
```

## 🛠️ Technologies & Packages

### State Management
- **flutter_bloc** (^8.1.3) - BLoC pattern for state management
- **equatable** (^2.0.5) - Value equality

### Navigation
- **go_router** (^12.1.3) - Declarative routing

### Localization
- **easy_localization** (^3.0.3) - Multi-language support

### UI & Animations
- **flutter_animate** (^4.3.0) - Smooth animations
- **lottie** (^2.7.0) - Lottie animations
- **flutter_svg** (^2.0.9) - SVG support
- **google_fonts** (^6.1.0) - Custom fonts
- **cached_network_image** (^3.3.0) - Image caching
- **font_awesome_flutter** (^10.6.0) - Icon library

### Forms & Validation
- **flutter_form_builder** (^9.1.1) - Form building
- **form_builder_validators** (^9.1.0) - Form validation

### Storage
- **shared_preferences** (^2.2.2) - Local storage

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- iOS development tools (for iOS)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd University_Major_Recommendation_flutter
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## 📦 Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🎨 Design System

### Color Palette

#### Light Theme
- Primary: Indigo (#6366F1)
- Secondary: Purple (#8B5CF6)
- Accent: Cyan (#06B6D4)
- Background: #F8FAFC
- Surface: #FFFFFF

#### Dark Theme
- Primary: Lighter Indigo (#818CF8)
- Secondary: Lighter Purple (#A78BFA)
- Accent: Lighter Cyan (#22D3EE)
- Background: #0F172A
- Surface: #1E293B

### Typography
- Font Family: Cairo (Arabic support)
- Google Fonts integration
- Responsive font sizes

### Animations
- Fade transitions
- Slide animations
- Scale effects
- Smooth page transitions

## 🌍 Localization

Translation files are located in `assets/translations/`:
- `en.json` - English translations
- `ar.json` - Arabic translations

To add a new language:
1. Create a new JSON file in `assets/translations/`
2. Add the locale to `supportedLocales` in `main.dart`
3. Implement the translations

## 📱 Screenshots

[Add screenshots here]

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- Your Name - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- Community contributors

## 📞 Support

For support, email support@example.com or open an issue in the repository.

---

Made with ❤️ using Flutter

