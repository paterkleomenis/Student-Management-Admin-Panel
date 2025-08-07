# Student Management Admin Panel

A Flutter-based admin panel for managing student data with a clean, responsive interface.

## Features

- Student data management (add, edit, delete, search)
- Excel import/export functionality
- Data visualization with charts
- Responsive design for desktop and web
- Multi-language support (English/Greek)
- Supabase integration for data storage

## Requirements

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- Supabase account for database

## Setup

1. Clone the repository:
```bash
git clone https://github.com/paterkleomenis/Student-Management-Admin-Panel.git
cd admin_panel
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create a `.env` file in the root directory with your Supabase credentials:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Run the application:
```bash
flutter run
```

## Usage

- **Dashboard**: View student statistics and charts
- **Students**: Manage student records with full CRUD operations
- **Import/Export**: Use Excel files to bulk import or export student data
- **Search**: Filter students by university, department, or year

## Technology Stack

- Flutter/Dart
- Supabase (Database & Auth)
- Excel package for file operations
- FL Chart for data visualization
- Provider for state management

## Project Structure

```
lib/
├── models/          # Data models
├── pages/           # UI screens
├── services/        # API and data services
├── utils/           # Helper functions
└── main.dart        # Application entry point
```
