# 🏫 Student Management Admin Panel

A professional Flutter-based admin panel for managing student dormitory applications with a clean, responsive interface and comprehensive internationalization support.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)

## ✨ Features

### 📊 Dashboard & Analytics
- Real-time application statistics and trends
- Document verification status overview
- Visual charts and data visualization
- Monthly application trends

### 👥 Student Management
- Complete student application management
- Advanced search and filtering
- Application status tracking (draft, submitted, under review, approved, rejected)
- Bulk operations for efficiency

### 📄 Document Management  
- Document upload and verification system
- Category-based document organization
- Bulk document approval/rejection
- Document compliance monitoring

### 🌐 Internationalization
- Multi-language support (English/Greek)
- Seamless language switching
- Localized data export
- Parameter-based translation system

### 📤 Import/Export
- Excel/CSV export with localized headers
- Customizable export fields
- Language-specific file naming
- Data integrity preservation

### 🎨 User Interface
- Responsive design for desktop and web
- Modern Material Design 3
- Dark/light theme support
- Professional typography with Google Fonts

## 🚀 Quick Start

### Prerequisites

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- Supabase account (for database and authentication)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/student-admin-panel.git
cd admin_panel
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Environment Configuration:**
   
   Create a `.env` file in the root directory:
```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Optional: Additional Configuration
APP_ENV=development
DEBUG_MODE=true
```

4. **Database Setup:**

   Set up your Supabase database with the required tables:
   - `dormitory_students` - Main student applications
   - `document_categories` - Document type definitions
   - `student_documents` - Uploaded documents metadata
   - `document_submissions` - Document submission tracking

5. **Run the application:**

   **For Development:**
```bash
# Using the development script
./scripts/dev.sh

# Or manually
flutter run -d web-server --web-port=3000
```

   **For Production:**
```bash
# Build for production
./scripts/build_production.sh

# Or manually
flutter build web --release
```

## 📱 Usage

### Admin Dashboard
- View real-time application statistics
- Monitor document verification queues
- Track application status distribution
- Access quick actions for common tasks

### Student Management
- **Search & Filter**: Find students by name, email, university, department
- **Application Review**: Approve/reject applications with status tracking
- **Bulk Operations**: Handle multiple applications efficiently
- **Export Data**: Generate Excel/CSV reports in multiple languages

### Document Verification
- **Review Documents**: Preview uploaded documents inline
- **Verification Workflow**: Approve/reject with detailed reasoning
- **Bulk Processing**: Handle multiple documents simultaneously
- **Compliance Monitoring**: Track completion rates by category

### Language Support
- **Seamless Switching**: Toggle between English and Greek instantly
- **Localized Export**: Data exports respect selected language
- **Parameter Translation**: Dynamic content with proper localization
- **Persistent Selection**: Language preference saved across sessions

## 🏗️ Technical Architecture

### Technology Stack
- **Frontend**: Flutter (Web & Desktop)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **State Management**: Provider pattern
- **Internationalization**: Custom service with JSON-based translations
- **Charts**: FL Chart for data visualization
- **File Operations**: Excel package for import/export
- **Navigation**: GoRouter for declarative routing

### Project Structure
```
lib/
├── config/          # Application configuration
├── models/          # Data models and entities
├── screens/         # UI screens and pages
│   ├── dashboard_screen.dart
│   ├── students_screen.dart
│   ├── login_screen.dart
│   └── ...
├── services/        # Business logic and API services
│   ├── student_service.dart
│   ├── document_service.dart
│   ├── auth_service.dart
│   ├── language_service.dart
│   └── excel_service.dart
├── widgets/         # Reusable UI components
├── utils/           # Helper functions and utilities
├── providers/       # State management providers
└── main.dart        # Application entry point
```

### Database Schema
```sql
-- Main student applications table
dormitory_students (
  id, name, family_name, birth_date, id_card_number,
  email, phone, university, department, year_of_study,
  application_status, created_at, updated_at, ...
)

-- Document management tables
document_categories (id, name, description, is_required, ...)
student_documents (id, student_id, category_id, file_path, status, ...)
document_submissions (id, student_id, submission_date, ...)
```

## 🌐 Internationalization

The application supports comprehensive internationalization:

### Supported Languages
- **English (en)** - Primary reference language
- **Greek (el)** - Secondary language with full localization

### Translation Features
- JSON-based translation files
- Parameter substitution for dynamic content
- Language-specific date and number formatting
- Localized export functionality
- Persistent language selection

### Adding New Languages

1. Create translation file: `assets/translations/[language_code].json`
2. Update `LanguageService` with new locale
3. Add language to `EasyLocalization` configuration
4. Test all UI components with the new language

## 🚀 Deployment

### Build for Production
```bash
# Using the production script
./scripts/build_production.sh

# Manual build
flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=DEBUG_MODE=false
```

### Hosting Options
- **Firebase Hosting**: Static web hosting with CDN
- **Netlify**: Continuous deployment from Git
- **Vercel**: Edge network deployment
- **Traditional Web Server**: Apache/Nginx with static files

### Environment Variables
Ensure your production environment has:
- `SUPABASE_URL`: Your production Supabase URL
- `SUPABASE_ANON_KEY`: Your production Supabase anonymous key



---
