# NOTEShub Mobile & Web Application

Cross-platform academic notes platform built with Flutter (Android, iOS, Web) migrating from the existing Next.js frontend while retaining the shared Firebase Firestore database, Firebase Authentication, and Cloudinary RAW asset storage.

---

## 1. Architecture Overview

The application follows clean layered architecture using the BLoC (Business Logic Component) and Cubit patterns:

```
mobile/lib/
├── core/
│   ├── constants/       # App-wide string constants and branding
│   ├── models/          # Typed data models (FileModel, SubjectModel, UserModel, OfflineDoc)
│   ├── network/         # Dio HTTP client with retry and timeouts
│   ├── repositories/    # Firestore data access layer (SubjectRepository, FileRepository, AuthRepository)
│   ├── services/        # Cloudinary upload, DownloadService, OfflineLibraryService
│   ├── storage/         # LocalStorageService (SharedPreferences) & web stubs
│   ├── theme/           # Material 3 dark academic navy theme (AppTheme, AppColors)
│   └── utils/           # FileUtils (magic byte checks, path sanitization, byte formatting)
├── features/
│   ├── admin/           # Admin login, dashboard, upload resource, subjects, resources
│   ├── auth/            # AuthBloc, authentication states, and role gating
│   ├── downloads/       # DownloadCubit, offline document library and management
│   ├── home/            # Public student home screen with active semester cards
│   ├── pdf_viewer/      # Syncfusion in-app PDF reader with jump-to-page and offline support
│   ├── search/          # In-memory cached acronym-aware search engine and SearchCubit
│   ├── semester/        # Semester curriculum screen with responsive 8-slot subject grid
│   └── subject/         # Subject detail screen: Modules 1–5, category tabs, file list
├── security/            # Security proposals, Cloudinary configuration, and deletion guides
└── shared/              # Reusable UI widgets, stat cards, dialogs, and bottom sheets
```

---

## 2. Student Functionality (Public & Login-Free)

- **Zero-Barrier Access**: Students browse all semesters, subjects, modules, categories, and PDFs without creating an account or logging in.
- **Academic Navigation**:
  - Semester overview (Semesters 1 through 8).
  - Subject discovery with acronym badges (e.g. `OS`, `WT`, `DBMS`).
  - Module tabs (Modules 1 to 5).
  - Resource categories: **Notes** (`notes`), **Question Banks** (`qbank`), and **Extra Resources** (`extra`).
- **Global Acronym Search**: Search by full text, acronyms, module numbers, or semesters with instantaneous in-memory results.
- **In-App PDF Reader**: High-performance PDF viewing using Syncfusion PDF Viewer with jump-to-page, bookmarking, and offline fallback.
- **Offline Library**:
  - Downloads PDFs directly to local application storage.
  - Automatically checks `%PDF-` magic byte signatures to prevent corrupted files.
  - Prevents path traversal via strict filename sanitization.
  - Synchronizes local registry with physical disk storage on launch.
  - Removing a download only purges the local file and never touches remote cloud assets.

---

## 3. Admin Portal & Content Management

- **Role-Gated Access**:
  - Email/password authentication via Firebase Auth.
  - Role resolution from Firestore document `users/{uid}`.
  - Only `author` and `owner` roles (plus client fallback `ownerUid`) are granted administrative privileges.
  - Students and unauthorized users are immediately signed out and rejected.
- **Live Metrics Dashboard**:
  - Live Firestore counters: total active semesters, total configured subjects, and total uploaded resources.
  - Quick shortcuts for uploading resources, managing subjects, and browsing files.
  - Recent uploads feed with direct PDF preview.
- **Cloudinary RAW Upload Pipeline**:
  - Unsigned multipart uploads to Cloudinary cloud `debfdnujc` using preset `college_notes`.
  - Zero-secret guarantee: API secrets are never embedded in the client application.
  - Client-side validation: magic byte verification (`%PDF-`), size ceiling (<= 50 MB), `.pdf` extension enforcement.
  - Atomic recovery strategy: if Cloudinary upload succeeds but Firestore index writing fails, the upload result is preserved with a "Retry Save" action without re-uploading the file.
- **Subject Management**:
  - Add new subjects to Semesters 1–8 (enforces slots 1–8 and prevents duplicate slots).
  - Inline subject renaming with instant Firestore synchronization.
- **Resource Management**:
  - Multi-criteria filtering by semester, subject, module, and category.
  - Inline renaming of study resources.
  - Security-enforced deletion lock: remote deletion is disabled in the client to prevent orphaned assets.

---

## 4. Backend & Firebase Configuration

- **Firebase Project ID**: `smart-college-notes`
- **Android Package**: `app.noteshub.mobile`
- **iOS Bundle ID**: `app.noteshub.mobile`
- **Configuration File**: `mobile/lib/firebase_options.dart` (generated via FlutterFire CLI).

### Firestore Schema

#### `users` Collection
- Document ID: Firebase Auth UID (`request.auth.uid`).
- `role`: String (`owner` | `author` | null).
- `name`: Optional String.

#### `subjects` Collection
- Document ID: `${semester}_${subject}` (e.g. `4_1`, `5_3`).
- `semester`: Integer (1 to 8).
- `subject`: Integer slot (1 to 8).
- `name`: String (non-empty).

#### `files` Collection
- Document ID: Auto-generated Firestore document ID.
- `semester`: Integer (1 to 8).
- `subject`: Integer (1 to 8).
- `module`: Integer (1 to 5).
- `type`: String (`notes` | `qbank` | `extra`).
- `name`: String (display name).
- `url`: String (Cloudinary secure delivery URL).
- `publicId`: String (Cloudinary public identifier).
- `createdAt`: Optional Timestamp.

---

## 5. Security Documentation & Policies

Additional security specifications are maintained inside `mobile/security/`:

1. [`firestore.rules`](security/firestore.rules): Proposed Firestore Security Rules enforcing public student reads, author/owner write gates, and role tampering prevention.
2. [`CLOUDINARY_SECURITY.md`](security/CLOUDINARY_SECURITY.md): Cloudinary console configuration guide, preset restrictions, and size ceilings.
3. [`SECURE_DELETION_PROPOSAL.md`](security/SECURE_DELETION_PROPOSAL.md): Recommended serverless Firebase Cloud Function architecture for secure, authenticated remote asset deletion.

---

## 6. Verification & Build Commands

Execute all builds and checks from the `mobile/` directory:

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Static analysis
flutter analyze

# 3. Automated unit and widget tests
flutter test

# 4. Web production build
flutter build web

# 5. Android debug APK build
flutter build apk --debug
```

---

## 7. Known Platform Behaviors

- **Web Platform**:
  - In-app PDF rendering utilizes Syncfusion Web canvas.
  - Document downloads on web trigger native browser download streams using Cloudinary `fl_attachment` URLs.
- **Android & iOS Platforms**:
  - Downloads are stored securely inside the application documents sandbox (`<AppDocuments>/noteshub_downloads/`).
  - Offline files are verified against `%PDF-` magic bytes before inclusion in the offline library.
