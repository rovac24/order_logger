# Order Logger Web - Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Core Features](#core-features)
4. [Technical Stack](#technical-stack)
5. [Project Structure](#project-structure)
6. [Code Documentation](#code-documentation)
7. [Deployment](#deployment)
8. [Development Guide](#development-guide)
9. [Configuration](#configuration)
10. [Quality Assurance](#quality-assurance)

---

## Project Overview

**Project Name:** Order Logger Web (order_logger_web)
**Version:** 1.0.0+1
**Type:** Flutter Web Application
**Platform:** Web (PWA-ready)

### Purpose
Order Logger is a web-based invoice processing system designed for Sales Operations (SOP) teams to capture, parse, and submit order data to Google Sheets. The application streamlines the workflow of extracting structured information from unstructured invoice text and logging it into a centralized database.

### Target Users
- Sales Operations Team Members (15 active users)
- Order Processing Specialists
- Invoice Management Personnel

### Key Value Propositions
1. **Automation:** Automatically parses invoice data from plain text
2. **Validation:** Real-time field validation with visual feedback
3. **Integration:** Direct submission to Google Sheets backend
4. **User Experience:** Simple paste-and-submit interface with dark/light mode
5. **Accessibility:** Web-based, no installation required, PWA-ready

---

## Architecture

### System Architecture

```
┌─────────────────┐
│   User Browser  │
│  (Flutter Web)  │
└────────┬────────┘
         │
         │ Paste Invoice Text
         ▼
┌─────────────────────────┐
│   Invoice Parser        │
│   (Regex-based)         │
│                         │
│   Extracts:             │
│   - Invoice #           │
│   - Customer Name       │
│   - License #           │
│   - Date                │
│   - Total Due           │
│   - State               │
│   - Pay To Entity       │
└────────┬────────────────┘
         │
         │ Parsed Data
         ▼
┌─────────────────────────┐
│   Validation Layer      │
│   - Required fields     │
│   - Format checks       │
│   - Visual feedback     │
└────────┬────────────────┘
         │
         │ HTTP GET Request
         ▼
┌─────────────────────────┐
│  Google Sheets API      │
│  (Apps Script Macro)    │
│                         │
│  Stores data in Sheet   │
└─────────────────────────┘
```

### Data Flow

1. **Input Stage:** User pastes invoice text into textarea
2. **Parsing Stage:** Regex patterns extract structured data
3. **Validation Stage:** Check for missing required fields
4. **Submission Stage:** User selects name and submits
5. **API Call:** HTTP GET request with query parameters
6. **Storage Stage:** Google Sheets macro writes data
7. **Feedback Stage:** Success/error message displayed

### Component Architecture

```
lib/
├── main.dart          # UI Layer & State Management
├── parser.dart        # Business Logic Layer (Parsing)
├── models.dart        # Data Models
└── sheets.dart        # API Integration Layer
```

---

## Core Features

### 1. Invoice Text Parsing

The application uses regex-based parsing to extract the following fields:

| Field | Pattern/Logic | Example |
|-------|---------------|---------|
| Invoice Number | `#INV-\d+` or `#\d+` | #INV-12345 |
| Customer Name | Line-based extraction | ABC Dispensary LLC |
| License Number | Line-based extraction | C11-0000123-LIC |
| Order Date | Date parsing with UTC conversion | December 1st 2024, 3:30 PM UTC |
| Total Due | Currency parsing | $1,234.56 |
| State | Regex: `, [A-Z]{2} \d{5}` | CA (from "City, CA 90210") |
| Pay To Entity | Keywords: GTI, Green Thumb Industries, Ascend | GTI |

**Parser Features:**
- Ordinal date formatting (1st, 2nd, 3rd, 4th, etc.)
- AM/PM time normalization
- Decimal currency handling with comma separators
- Multi-line text processing
- Case-insensitive entity matching

### 2. Real-Time Validation

**Required Fields:**
- Invoice Number
- Customer Name
- License Number
- Total Due
- State
- Pay To Entity (Client)

**Validation Feedback:**
- Visual indicators with emojis (⚠️ for missing fields)
- Color-coded field display (blue for valid, pink for missing)
- Disabled submit button when fields are missing
- Warning message count display

### 3. User Interface Features

**Main Interface:**
- Material Design 3 components
- Responsive layout for all screen sizes
- Dark/light theme toggle
- Paste button with clipboard integration
- Team member dropdown (15 SOP team members)
- Real-time parsing feedback
- Upload status indicators (✅ ❌ ⏳)
- Parsed data preview card

**UX Enhancements:**
- Auto-save selected user name (SharedPreferences)
- Loading states during submission
- Success message auto-clear (2 seconds)
- Duplicate upload prevention
- Clear error messaging

### 4. Google Sheets Integration

**Submission Method:** HTTP GET request with query parameters

**Parameters Sent:**
- `invoice` - Invoice number
- `state` - US state code
- `customer` - Customer name
- `license` - License number
- `total` - Total amount due
- `submittedBy` - SOP team member name
- `dateUtc` - Formatted order date
- `payTo` - Pay to entity
- `edits` - Additional notes/edits (always "N/A")

**Error Handling:**
- HTTP status code validation
- Try-catch blocks for network errors
- User-friendly error messages
- Logging to console for debugging

---

## Technical Stack

### Frontend Framework
- **Flutter:** ^3.38.6
- **Dart SDK:** >=3.10.7 <4.0.0
- **Web Renderer:** CanvasKit (for optimal performance)

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6      # iOS-style icons
  http: ^1.2.0                 # HTTP client for API calls
  intl: ^0.20.2                # Date/number formatting
  shared_preferences: ^2.2.2   # Local storage

dev_dependencies:
  flutter_lints: ^3.0.0        # Code quality rules
  flutter_test:
    sdk: flutter               # Testing framework
```

### Development Tools
- **Flutter Analyzer:** Strict linting with 70+ rules
- **GitHub Actions:** Automated CI/CD pipeline
- **Vercel:** Primary hosting platform
- **Netlify:** Backup hosting configuration

---

## Project Structure

```
order_logger/
│
├── lib/                              # Application source code
│   ├── main.dart                     # Entry point & UI (11.3KB)
│   │   ├── MyApp (StatelessWidget)
│   │   └── OrderLoggerScreen (StatefulWidget)
│   │       ├── Theme management
│   │       ├── UI components
│   │       ├── State management
│   │       └── Event handlers
│   │
│   ├── parser.dart                   # Invoice parsing logic (4.3KB)
│   │   └── InvoiceParser class
│   │       ├── parse() - Main parsing method
│   │       ├── _extractInvoiceNumber()
│   │       ├── _extractCustomerName()
│   │       ├── _extractLicenseNumber()
│   │       ├── _extractState()
│   │       ├── _extractTotalDue()
│   │       ├── _extractPayToEntity()
│   │       ├── _extractOrderDate()
│   │       ├── _formatDateWithOrdinal()
│   │       └── _getOrdinalSuffix()
│   │
│   ├── models.dart                   # Data models (0.47KB)
│   │   ├── ParsedInvoice (Active)
│   │   └── InvoiceData (Legacy/Unused)
│   │
│   └── sheets.dart                   # Google Sheets API (0.77KB)
│       └── sendToGoogleSheets() - HTTP submission
│
├── web/                              # Web platform files
│   ├── index.html                    # HTML entry point
│   ├── manifest.json                 # PWA manifest
│   ├── favicon.png
│   └── icons/                        # PWA icons
│       ├── Icon-192.png
│       ├── Icon-512.png
│       ├── Icon-maskable-192.png
│       └── Icon-maskable-512.png
│
├── test/
│   └── widget_test.dart              # Unit/widget tests
│
├── .github/
│   └── workflows/
│       └── deploy.yml                # CI/CD pipeline
│
├── pubspec.yaml                      # Package configuration
├── pubspec.lock                      # Dependency lock file
├── analysis_options.yaml             # Linter configuration
├── vercel.json                       # Vercel deployment config
├── netlify.toml                      # Netlify build config
├── DEPLOYMENT.md                     # Deployment guide
├── README.md                         # Project README
└── Claude.md                         # This documentation file
```

---

## Code Documentation

### main.dart

**Purpose:** Main application entry point, UI components, and state management

**Key Components:**

```dart
// Application root
class MyApp extends StatelessWidget
  - Configures MaterialApp
  - Sets up theming
  - Defines home screen

// Main screen with order logging functionality
class OrderLoggerScreen extends StatefulWidget
  State Variables:
    - _controller: TextEditingController (invoice text input)
    - _parsedInvoice: ParsedInvoice? (parsed data)
    - _statusMessage: String (feedback to user)
    - _isUploading: bool (submission state)
    - _selectedName: String? (team member selection)
    - _isDarkMode: bool (theme toggle)
    - _prefs: SharedPreferences? (persistent storage)
```

**Key Methods:**

1. `_initPreferences()` - Loads saved user preferences
2. `_loadSelectedName()` - Retrieves last selected team member
3. `_saveSelectedName(String)` - Persists team member selection
4. `_parseInvoice()` - Triggers invoice parsing
5. `_uploadData()` - Submits parsed data to Google Sheets
6. `_getMissingFields()` - Validates required fields
7. `_pasteFromClipboard()` - Pastes clipboard content

**UI Sections:**
- App bar with theme toggle
- Invoice input textarea
- Paste button
- Team member dropdown
- Parsed data preview card
- Submit button
- Status message display

**SOP Team Members:**
1. Angel Alonzo
2. Arturo Juarez
3. Ayesha Reyes
4. David Salazar
5. Dusan Markovic
6. Emily Funez
7. Ernesto Salazar
8. Juan Bayer
9. Laura Martinez
10. Miguel Barreto
11. Ognjen Petrovic
12. Paola Castañon
13. Rodolfo Valdez
14. Ruben Hernandez
15. Teodora Ljubičić

### parser.dart

**Purpose:** Extract structured data from unstructured invoice text

**Main Class:**

```dart
class InvoiceParser {
  static ParsedInvoice parse(String invoiceText)
}
```

**Parsing Methods:**

1. **_extractInvoiceNumber(String text)**
   - Regex: `#INV-\d+` or `#\d+`
   - Returns: Invoice number string

2. **_extractCustomerName(String text)**
   - Logic: Line after "Customer Name:"
   - Returns: Customer name string

3. **_extractLicenseNumber(String text)**
   - Logic: Line after "License Number:"
   - Returns: License number string

4. **_extractState(String text)**
   - Regex: `, [A-Z]{2} \d{5}` (from address)
   - Returns: 2-letter state code

5. **_extractTotalDue(String text)**
   - Logic: Amount after "Total Due:"
   - Regex: `\$?[\d,]+\.?\d*`
   - Returns: Formatted currency string

6. **_extractPayToEntity(String text)**
   - Keywords: "GTI", "Green Thumb Industries", "Ascend"
   - Returns: Pay to entity name

7. **_extractOrderDate(String text)**
   - Logic: Datetime after "Order Placed:"
   - Format: "MMMM d'ordinal' yyyy, h:mm a 'UTC'"
   - Example: "December 1st 2024, 3:30 PM UTC"
   - Returns: Formatted date string

**Helper Methods:**

- `_formatDateWithOrdinal(DateTime)` - Formats date with ordinal suffix
- `_getOrdinalSuffix(int)` - Returns "st", "nd", "rd", or "th"

**Example Input:**
```
Invoice #INV-12345
Customer Name: ABC Dispensary LLC
License Number: C11-0000123-LIC
Order Placed: December 1, 2024 3:30 PM
123 Main St, Los Angeles, CA 90210
Total Due: $1,234.56
Pay To: Green Thumb Industries
```

**Example Output:**
```dart
ParsedInvoice(
  invoiceNumber: "INV-12345",
  customerName: "ABC Dispensary LLC",
  licenseNumber: "C11-0000123-LIC",
  orderPlaced: "December 1st 2024, 3:30 PM UTC",
  totalDue: "1234.56",
  state: "CA",
  client: "Green Thumb Industries"
)
```

### models.dart

**Purpose:** Data models for invoice representation

**Active Model:**

```dart
class ParsedInvoice {
  final String invoiceNumber;
  final String customerName;
  final String licenseNumber;
  final String orderPlaced;
  final String totalDue;
  final String state;
  final String client;  // Pay to entity

  ParsedInvoice({
    this.invoiceNumber = '',
    this.customerName = '',
    this.licenseNumber = '',
    this.orderPlaced = '',
    this.totalDue = '',
    this.state = '',
    this.client = '',
  });
}
```

**Legacy Model (Unused):**
```dart
class InvoiceData {
  // Appears to be from earlier version
  // Not currently used in codebase
}
```

### sheets.dart

**Purpose:** Google Sheets API integration

**Main Function:**

```dart
Future<void> sendToGoogleSheets(ParsedInvoice invoice, String submittedBy) async
```

**Implementation:**
- Method: HTTP GET request
- Endpoint: Google Apps Script macro URL
- Parameters: invoice, state, customer, license, total, submittedBy, dateUtc, payTo, edits
- Error Handling: Status code validation with exceptions

**Example Request:**
```
GET https://script.google.com/macros/s/[SCRIPT_ID]/exec?
  invoice=INV-12345&
  state=CA&
  customer=ABC+Dispensary+LLC&
  license=C11-0000123-LIC&
  total=1234.56&
  submittedBy=Ruben+Hernandez&
  dateUtc=December+1st+2024%2C+3%3A30+PM+UTC&
  payTo=Green+Thumb+Industries&
  edits=N%2FA
```

**Error Handling:**
```dart
if (response.statusCode == 200) {
  print('Data sent successfully to Google Sheets');
} else {
  throw Exception('Failed to send data. Status: ${response.statusCode}');
}
```

---

## Deployment

### CI/CD Pipeline

**GitHub Actions Workflow:** `.github/workflows/deploy.yml`

**Trigger:** Push to `main` branch

**Jobs:**

#### 1. Build Job
```yaml
runs-on: ubuntu-latest
steps:
  - Checkout repository
  - Setup Flutter 3.38.6
  - Install dependencies (flutter pub get)
  - Run code analysis (flutter analyze)
  - Build web release (flutter build web --release --web-renderer canvaskit)
  - Upload build artifacts (retention: 1 day)
```

#### 2. Deploy Job
```yaml
needs: build
runs-on: ubuntu-latest
steps:
  - Download build artifacts
  - Deploy to Vercel (production)
```

**Required Secrets:**
- `VERCEL_TOKEN` - Vercel authentication token
- `VERCEL_ORG_ID` - Vercel organization ID
- `VERCEL_PROJECT_ID` - Vercel project ID

### Hosting Platforms

#### Primary: Vercel

**Configuration:** `vercel.json`

```json
{
  "routes": [
    { "src": "/(.*)", "dest": "/" }  // SPA routing
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=3600" }
      ]
    },
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

**Features:**
- Single Page Application routing
- 1-hour cache for general content
- 1-year immutable cache for assets
- Automatic HTTPS
- Global CDN

#### Backup: Netlify

**Configuration:** `netlify.toml`

```toml
[build]
  command = "flutter build web --release --web-renderer canvaskit"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.19.6"
```

### Manual Deployment

**Prerequisites:**
- Flutter SDK 3.38.6+
- Dart SDK 3.10.7+
- Vercel CLI (optional)

**Build Steps:**
```bash
# 1. Install dependencies
flutter pub get

# 2. Run code analysis
flutter analyze

# 3. Build for production
flutter build web --release --web-renderer canvaskit

# 4. Output location
# build/web/
```

**Deploy to Vercel:**
```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

---

## Development Guide

### Prerequisites

**Required Software:**
- Flutter SDK: 3.38.6 or higher
- Dart SDK: 3.10.7 or higher
- Git
- Code editor (VS Code, Android Studio, or IntelliJ IDEA)

**Optional Tools:**
- Chrome (for web debugging)
- Flutter DevTools
- Vercel CLI

### Getting Started

#### 1. Clone Repository
```bash
git clone <repository-url>
cd order_logger
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Run Code Analysis
```bash
flutter analyze
```

#### 4. Run Application (Debug Mode)
```bash
flutter run -d chrome
```

#### 5. Build for Production
```bash
flutter build web --release --web-renderer canvaskit
```

### Development Workflow

#### Hot Reload
- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

#### Running Tests
```bash
flutter test
```

#### Code Formatting
```bash
flutter format lib/
```

#### Dependency Updates
```bash
flutter pub upgrade
flutter pub outdated
```

### Environment Setup

**VS Code Extensions (Recommended):**
- Dart
- Flutter
- Flutter Widget Snippets
- Prettier (for Markdown/JSON)

**Android Studio/IntelliJ Plugins:**
- Flutter
- Dart

### Debugging

**Web Debugging:**
```bash
flutter run -d chrome --web-renderer canvaskit
```

**DevTools:**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Console Logging:**
```dart
print('Debug message');
debugPrint('Debug message with auto-wrapping');
```

### Common Development Tasks

#### Adding a New Team Member
1. Open `lib/main.dart`
2. Add name to `sopTeamMembers` list (alphabetically)
3. Run `flutter analyze` to check for issues

#### Modifying Parser Logic
1. Open `lib/parser.dart`
2. Update extraction methods
3. Test with sample invoice data
4. Run `flutter analyze`

#### Changing Google Sheets Endpoint
1. Open `lib/sheets.dart`
2. Update `url` variable
3. Ensure query parameters match Apps Script expectations

#### Updating Dependencies
```bash
# Update specific package
flutter pub upgrade <package_name>

# Update all packages
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

---

## Configuration

### analysis_options.yaml

**Purpose:** Dart analyzer and linter configuration

**Base Configuration:**
```yaml
include: package:flutter_lints/flutter.yaml
```

**Analyzer Settings:**
```yaml
analyzer:
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
  errors:
    missing_required_param: error
    missing_return: error
  language:
    strict-casts: true
    strict-inference: true
```

**Key Linter Rules:**
- `always_declare_return_types` - Explicit return types
- `camel_case_types` - Type naming convention
- `lines_longer_than_80_chars` - Line length limit
- `prefer_final_fields` - Immutability
- `prefer_final_locals` - Immutability
- `avoid_print` - Use proper logging (warning only)
- `unnecessary_null_checks` - Code cleanliness

**Total Rules:** 70+ enforced rules

### pubspec.yaml

**Package Metadata:**
```yaml
name: order_logger_web
description: "A new Flutter project."
version: 1.0.0+1
```

**Environment Constraints:**
```yaml
environment:
  sdk: '>=3.10.7 <4.0.0'
```

**Flutter Configuration:**
```yaml
flutter:
  uses-material-design: true
```

### Web Configuration

#### manifest.json (PWA)
```json
{
  "name": "order_logger_web",
  "short_name": "order_logger_web",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0175C2",
  "theme_color": "#0175C2",
  "description": "A new Flutter project.",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

**PWA Features:**
- Installable as standalone app
- Custom app icons
- Portrait orientation
- Flutter blue theme color

#### index.html
- Service worker registration
- Flutter bootstrap script
- Loading indicator
- Responsive viewport settings

---

## Quality Assurance

### Code Quality Standards

**Enforced via:**
- Flutter Analyzer (static analysis)
- Flutter Lints 3.0.0 (70+ rules)
- GitHub Actions CI pipeline

**Quality Metrics:**
- 0 analyzer errors required for merge
- All linter rules must pass
- Code must build successfully

### Testing Strategy

**Current Tests:**
- Widget tests in `test/widget_test.dart`

**Testing Recommendations:**

1. **Unit Tests**
   - Parser logic validation
   - Model creation/serialization
   - Date formatting functions

2. **Widget Tests**
   - UI component rendering
   - User interaction flows
   - Theme switching

3. **Integration Tests**
   - End-to-end invoice submission
   - API error handling
   - Clipboard operations

**Example Test:**
```dart
testWidgets('Submit button is disabled when fields are missing', (tester) async {
  await tester.pumpWidget(MyApp());

  final submitButton = find.widgetWithText(ElevatedButton, 'Upload to Google Sheets');
  expect(tester.widget<ElevatedButton>(submitButton).onPressed, null);
});
```

### Performance Monitoring

**Build Performance:**
- CanvasKit renderer for optimal rendering
- Asset caching (1 year for immutable assets)
- Code splitting and lazy loading
- Minified production builds

**Runtime Performance:**
- Minimal rebuilds with StatefulWidget
- Efficient regex parsing
- Debounced state updates

### Security Best Practices

**Current Implementation:**
- HTTPS-only communication
- No sensitive data in local storage
- Input validation before submission
- CORS-compliant API calls

**Recommendations:**
1. Move Google Sheets URL to environment variables
2. Implement authentication for user selection
3. Add CSRF protection if applicable
4. Regular dependency updates for security patches

### Accessibility

**WCAG Compliance:**
- Semantic HTML structure
- Material Design contrast ratios
- Keyboard navigation support
- Screen reader friendly labels

**Improvements Needed:**
- ARIA labels for custom components
- Focus management
- Alternative text for icons

---

## Maintenance & Support

### Dependency Management

**Update Schedule:**
- Monthly: Check for security updates
- Quarterly: Review and update dependencies
- Annually: Major version upgrades

**Update Commands:**
```bash
flutter pub outdated
flutter pub upgrade --major-versions
```

### Monitoring

**Key Metrics to Track:**
- Deployment success rate
- API response times
- Error rates in Google Sheets submissions
- User adoption (by team member)

### Troubleshooting

**Common Issues:**

1. **Build Failures**
   - Clear build cache: `flutter clean`
   - Reinstall dependencies: `flutter pub get`
   - Check Flutter version: `flutter --version`

2. **Upload Errors**
   - Verify Google Sheets URL
   - Check network connectivity
   - Review browser console for CORS errors

3. **Parsing Issues**
   - Validate invoice text format
   - Check regex patterns in parser.dart
   - Add logging to extraction methods

### Version History

**Recent Changes:**
```
b34251e - fix 24
d64ee68 - Fix flutter_lints dependency and analysis options
913a7c5 - Update Dart SDK constraint to >=3.10.7
604e583 - Update Flutter version in deploy workflow
38904b1 - Refactor deploy.yml for Flutter version and steps
```

### Contributing

**Workflow:**
1. Create feature branch from `main`
2. Implement changes
3. Run `flutter analyze` and `flutter test`
4. Commit with descriptive message
5. Push and create pull request
6. Wait for CI/CD checks to pass
7. Merge to `main` (triggers deployment)

**Commit Message Format:**
```
<type>: <description>

[optional body]

Examples:
feat: Add new team member to dropdown
fix: Correct state extraction regex
docs: Update deployment instructions
refactor: Simplify parser logic
```

---

## Future Enhancements

### Planned Features
1. Edit history tracking (currently always "N/A")
2. Bulk invoice upload
3. Invoice validation rules configuration
4. Export parsed data to CSV
5. Admin dashboard for analytics
6. Offline support with sync
7. Mobile responsive improvements
8. Authentication system
9. Role-based access control
10. Audit logging

### Technical Debt
1. Remove unused `InvoiceData` model
2. Add comprehensive test coverage
3. Implement environment variables for API URLs
4. Add error tracking service (e.g., Sentry)
5. Improve accessibility (ARIA labels)
6. Add performance monitoring
7. Implement proper logging framework
8. Add API retry logic with exponential backoff

### Scalability Considerations
- Consider backend API instead of direct Google Sheets integration
- Implement rate limiting
- Add caching layer for team member data
- Database migration from Google Sheets to proper DB
- Microservices architecture for parsing/validation

---

## Appendix

### Glossary

- **SOP:** Sales Operations
- **PWA:** Progressive Web App
- **CI/CD:** Continuous Integration/Continuous Deployment
- **CanvasKit:** Flutter's web rendering engine using WebAssembly
- **Apps Script:** Google's JavaScript platform for Google Workspace automation
- **Regex:** Regular Expression (pattern matching)

### External Resources

**Flutter Documentation:**
- https://flutter.dev/docs
- https://api.flutter.dev/

**Dart Documentation:**
- https://dart.dev/guides

**Deployment Platforms:**
- Vercel: https://vercel.com/docs
- Netlify: https://docs.netlify.com

**Dependencies:**
- http package: https://pub.dev/packages/http
- shared_preferences: https://pub.dev/packages/shared_preferences
- intl: https://pub.dev/packages/intl

### Contact Information

**Repository:** order_logger
**Platform:** Web
**Status:** Production
**Last Updated:** January 2026

---

*This documentation was generated for the Order Logger Web project. For the latest updates, refer to the repository's main branch.*
