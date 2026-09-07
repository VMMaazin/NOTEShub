# NOTEShub - Complete Technical Project Report

Welcome to the comprehensive technical documentation and project report for **NOTEShub**. This document details the architectural layout, core systems, database schema, file handling workflows, Progressive Web App (PWA) configurations, and runtime execution patterns that define the application.

---

## 📊 Executive Summary & Project Overview

**NOTEShub** is a premium, high-performance web application designed for students and educators to organize, search, share, and access academic resources (such as lecture notes, previous question banks, and extra reference materials). 

Built on **Next.js (App Router)** and styled using modern responsive design paradigms via **Tailwind CSS**, it operates as a fully capable **Progressive Web App (PWA)**. The application features a comprehensive **offline-first capability** powered by browser **IndexedDB**, allowing students to download critical lecture notes and read them through a custom built-in PDF viewer even in dead zones or during network outages.

---

## 🛠️ Technology Stack & Integrations

The architecture is built on a modern, decoupled stack, prioritizing speed, offline capabilities, secure authentication, and premium user experience:

| Layer | Technology | Purpose / Implementation Details |
| :--- | :--- | :--- |
| **Core Framework** | Next.js 13.5.1 (App Router) | Server-side rendering support, dynamic route resolution, optimization features, and serverless API endpoints. |
| **Language** | TypeScript | Strong typing across components, APIs, database documents, and context states. |
| **Styling & UI** | Tailwind CSS & Shadcn UI | Harmonious theme systems, custom glassmorphism, responsive grids, and pre-packaged accessible primitives (Radix UI). |
| **Animations** | Framer Motion | Fluid spring physics animations, micro-interactions, layout transitions, and tab switching animations. |
| **Authentication** | Firebase Authentication | Secure email & password auth with custom forgot-password and security-focused first-login workflows. |
| **Cloud Database** | Firebase Firestore | Reactive real-time document sync for subjects, files meta, user roles, and profile details. |
| **Cloud Asset Store** | Cloudinary | Secure raw storage hosting for multiple document formats (PDFs, PPTs, DOCs) with custom dynamic attachment downloads. |
| **Offline Storage** | HTML5 IndexedDB | Local client-side relational storage of file Blobs and file metadata. |
| **PDF Rendering** | `@react-pdf-viewer/core` | High-fidelity canvas-based rendering of PDFs with support for offline web workers (`pdfjs-dist`). |

---

## 📁 System Architecture & Directory Layout

Below is the directory mapping of the codebase, detailing the purpose of every module:

```text
NOTEShub/
├── .bolt/                  # Bolt IDE environment details
├── app/                    # Next.js App Router root folder
│   ├── admin/              # Admin pages
│   │   └── login/          # LoginPage component for authors and owners
│   ├── api/                # Next.js Serverless API endpoints
│   │   ├── delete-file/    # Secure API route to destroy raw files on Cloudinary
│   │   └── notify/         # Notification utility framework
│   ├── downloads/          # Offline files library dashboard page
│   ├── offline/            # PWA Offline fallback page
│   ├── onboarding/         # First-time login password-reset enforcement page
│   ├── semester/           # Semester pages directory
│   │   └── 4/              # Active Semester 4 routing folder
│   │       ├── page.tsx    # List of subjects under Semester 4
│   │       └── subject/    # Dynamic subject routes
│   │           └── [subjectId]/ # Individual Subject portal (5 modules, upload capabilities)
│   ├── globals.css         # Global stylesheets, fonts, and dark mode theme system
│   ├── layout.tsx          # Root Layout wrapping fonts, analytics, and providers
│   ├── providers.tsx       # Core provider context list (Themes, Firebase Auth, Toaster, BackToTop)
│   └── template.tsx        # Route transition animators
├── components/             # Reusable UI component modules
│   ├── ui/                 # Accessible primitives (Shadcn components, Radix UI)
│   ├── BackToTop.tsx       # Floating scroll-to-top handler
│   ├── DownloadModal.tsx   # Interactive modal presenting Cloud or Local Offline download paths
│   ├── FileList.tsx        # Active documents viewer, dynamic downloader, and administrative controller
│   ├── HomeSearch.tsx      # Debounced semantic multi-term search bar with acronym capabilities
│   ├── ModuleCard.tsx      # Dynamic visual indicator for active studies
│   ├── Navbar.tsx          # Interactive header with theme toggle, account controls, and mobile overlays
│   ├── PdfViewerModal.tsx  # Advanced full-screen PDF view running cached web workers
│   └── UploadFile.tsx      # Multi-format raw Cloudinary document uploader
├── context/                # Context modules
│   └── AuthContext.tsx     # Firebase Auth listener & Firestore-based Role resolver
├── hooks/                  # Custom React hooks
│   └── use-toast.ts        # UI toast notifier controls
├── lib/                    # Application utility libraries
│   ├── db.ts               # Offline IndexedDB database controller
│   ├── firebase.ts         # Firebase initialization configuration
│   └── utils.ts            # Class merging and design utility classes
├── public/                 # Static public assets
│   ├── icons/              # Brand and PWA logos
│   ├── manifest.json       # PWA Application manifest configuration
│   ├── sw.js               # Service Worker caching rules script
│   └── workbox-*.js        # PWA Workbox runtime bundle
├── next.config.js          # Next.js configuration and detailed next-pwa caching setup
├── package.json            # Node project configurations and dependencies
├── tailwind.config.ts      # Custom Tailwind styling variables, keyframes, and themes
└── tsconfig.json           # TypeScript compilation config
```

---

## 🔄 Architectural System Flows

### 1. Client Reading & Selection Flow

```mermaid
graph TD
    A[Home Page] --> B{Choose Semester}
    B -- Semester 4 --> C[Semester 4 Dashboard]
    B -- Semester 1, 2, 3 --> D[Locked - Future Scope]
    C --> E[Select Subject 1-8]
    E --> F[Subject Hub]
    F --> G{Select Module Tab 1-5}
    G --> H[File Category: Notes]
    G --> I[File Category: Question Banks]
    G --> J[File Category: Extra Resources]
    H & I & J --> K{Action}
    K -->|View| L[Custom PDF Viewer running offline workers]
    K -->|Download| M[Download Modal]
```

### 2. Administrator Document Upload Flow

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Authorized Role (Owner/Author)
    participant Client as UploadFile Component
    participant Cloudinary as Cloudinary RAW Asset API
    participant Firestore as Firestore Database
    participant UI as Dynamic Reactive List

    Admin->>Client: Selects file (PDF/PPT/DOC)
    activate Client
    Client->>Client: Context Validation (Semester, Subject, Module, Type)
    Client->>Cloudinary: POST Form Data (RAW upload preset)
    activate Cloudinary
    Cloudinary-->>Client: Returns JSON with secure_url & public_id
    deactivate Cloudinary
    Client->>Firestore: Add document to "files" collection
    activate Firestore
    Firestore-->>Client: Document created
    deactivate Firestore
    Client->>UI: Reset file input & Trigger reactive UI update
    deactivate Client
    UI-->>Admin: Document instantly visible in module category
```

### 3. Progressive Web App (PWA) Offline & Caching Flow

```mermaid
flowchart TD
    A[Client makes Request] --> B{Service Worker Active?}
    B -- No --> C[Standard Network Request]
    B -- Yes --> D{Is URL matched by Cache Rule?}
    D -- PDF Worker / Static Files / Downloads HTML --> E{Network Available?}
    E -- Yes --> F[Fetch from Network & Update Cache]
    E -- No --> G[Serve immediately from Service Worker Cache]
    D -- Other Assets / API calls --> H{Network Available?}
    H -- Yes --> I[Normal Web fetch]
    H -- No --> J[Redirect to /offline Fallback Document]
    J --> K[Link to /downloads Dashboard]
    K --> L[Retrieve Binary Blob files from IndexedDB]
```

---

## ⚡ Technical deep-dives & Core Features

### 🚀 1. The Offline-First Paradigm: IndexedDB Sync (`lib/db.ts`)
To achieve true offline independence, NOTEShub implements a custom **IndexedDB wrapper** inside client browsers, treating it as a local relational data store.

* **Database Schema (`OfflineFile` Interface)**:
  ```typescript
  export interface OfflineFile {
      id: string;          // Firestore Document ID
      name: string;        // Name of the uploaded file
      subject: number;     // Subject index (1-8)
      semester: number;    // Semester index (4)
      module: number;      // Module index (1-5)
      type: string;        // "notes" | "qbank" | "extra"
      blob: Blob;          // Actual file binary contents stored in IndexedDB
      size: number;        // Size in bytes
      downloadedAt: number;// Timestamp of download
      mimeType: string;    // E.g., "application/pdf"
      remoteUrl: string;   // Cloudinary secure link
  }
  ```

* **Core Transactions**:
  1. **Saving Files**: Opens `NotesHubDB`, creates a `downloads` object store using `id` as the key path, and writes the entire binary file `Blob` along with metadata inside a `readwrite` transaction.
  2. **Retrieving Metadata (`getFiles`)**: Performs a read cursor operation to fetch all downloaded items, stripping out the massive binary `blob` field so memory footprint remains small while generating lists.
  3. **Retrieving Files (`getFile`)**: Extracts a single file including its binary blob so it can be instantly rendered in the browser viewport.
  4. **Quota Check (`checkQuota`)**: Utilizes `navigator.storage.estimate()` to inspect how much space the app consumes versus the system limit, presenting a detailed usage meter inside the offline UI.

---

### 📥 2. High-Performance Client Downloads (`components/DownloadModal.tsx`)
When a user clicks "Download", they are presented with a selection modal detailing two distinct workflows:

#### Path A: Download to Device
To bypass browser iframe blockades and standard inline PDF openings, the application converts standard Cloudinary URLs into an attachment route by substituting the `/upload/` component with `/upload/fl_attachment/`.
```javascript
const downloadUrl = file.url.replace("/upload/", "/upload/fl_attachment/");
```
This forces the browser to immediately trigger a native file save to the OS system downloads folder.

#### Path B: Download in App (Offline Storage)
Downloads the document directly within the app memory space:
1. **Network Fetching & Progress Tracking**: Calls `fetch(file.url)` to get the resource. By obtaining a reader from the response stream `response.body.getReader()`, the app processes the file chunk by chunk, tracking accumulated data lengths against `Content-Length` headers to compute and animate an accurate loading bar (`0%` to `100%`).
2. **Binary Conversion**: Gathers all downloaded chunks and packages them into a single browser `Blob` object:
   ```javascript
   const blob = new Blob(chunks, { type: response.headers.get("Content-Type") || "application/pdf" });
   ```
3. **IndexedDB Write**: Stores the resulting blob into IndexedDB via `saveFile()`.
4. **Opening Offline Files**: Inside the `/downloads` dashboard, cached files are opened offline using object URLs:
   ```javascript
   const file = await getFile(id);
   const url = URL.createObjectURL(file.blob);
   window.open(url, "_blank");
   setTimeout(() => URL.revokeObjectURL(url), 60000); // Clean up memory pointers safely
   ```

---

### 🔍 3. Intelligent Multi-Term Search Engine (`components/HomeSearch.tsx`)
The home search input provides an instant matching mechanism across all subjects and files:
* **Debounced Lazy-Loading**: Rather than querying Firestore on every single stroke, search queries are held in state. Once the user types, a single batch query pulls **all** subjects and **all** files from Firestore and stores them in client-side arrays. All subsequent filtering is performed instantly in-memory, avoiding Firestore read fatigue.
* **Semantic Split-Matching**: Breaks queries into individual keywords (e.g. searching `"wt mod 2"` creates a search keyword array `["wt", "mod", "2"]`).
* **Acronym Generator**: Automatically generates short-hands of subjects in real time (e.g., "Web Technology" maps to `wt`, "Operating Systems" maps to `os`). 
* **Search Matching**: A file is returned only if **every** search term is contained in at least one of its attributes (File Name, Subject Name, Subject Acronym, File Type, or Module Number).

---

### 🛡️ 4. Onboarding Security and Role-Based Controls (`AuthContext.tsx`)
Authentication incorporates a secure onboarding gate:
* **First-Time Password Enforcement (`app/onboarding`)**: When users are created manually by an administrator, they receive a temporary credential. On their very first login, the `OnboardingPage` intercepts the session, prompts them that they must reset their password, fires off a secure Firebase `sendPasswordResetEmail` routine, immediately terminates their session via `signOut`, and returns them to login.
* **Role Resolver**: Every session retrieves details from a dedicated user profile document inside `users/{uid}` in Firestore. It determines the user's role:
  * **`owner` / `author`**: Gains administrative command. Instantly exposes file upload triggers (`UploadFile`), file rename inputs, and subject renaming controls across subject dashboards.
  * **Guest / Student**: Read-only, access to downloads and custom viewers.

---

### 🐳 5. Cloudinary raw storage & backend API
Because Next.js runs on serverless functions in cloud environments (like Vercel or Netlify), standard disk-based file saving is volatile. NOTEShub uses Cloudinary as a dynamic media engine.

* **Raw Presets**: Files are uploaded to Cloudinary's `/raw/upload` endpoint rather than the default image uploader. This preserves PPTs, DOCs, and PDFs in their raw binary states.
* **File Deletion Handler (`app/api/delete-file/route.ts`)**: To prevent orphan file leaks on the cloud, when an administrator deletes a document, the client triggers a POST request to our Next.js API. The endpoint initializes Cloudinary on the backend using private environment variables and securely destroys the cloud asset using its resource uploader:
  ```typescript
  await cloudinary.uploader.destroy(publicId, { resource_type: "raw" });
  ```

---

## 🌐 Progressive Web App (PWA) Setup

NOTEShub utilizes `@next-pwa` within `next.config.js` to create standard-compliant, offline-capable application packages.

### Workbox Caching Configurations
Our configuration details customized caching mechanisms:
1. **Fallback Documents**: In case of lost connectivity, requests for standard HTML documents default to the offline page:
   ```javascript
   fallbacks: { document: "/offline" }
   ```
2. **Downloads HTML Cache**: Employs `StaleWhileRevalidate` with an expiration rule of 30 days to store the `/downloads` dashboard offline.
3. **PDF Worker Cache**: Uses a `CacheFirst` strategy targeting the PDFJS worker hosted on CDN (`unpkg.com`) for a period of up to 1 year, ensuring the custom PDF reader works offline without repeating external lookups.
4. **Webpack Config**: Adjusts Next's Webpack rules by turning off `canvas` module resolution inside client bundles:
   ```javascript
   webpack: (config) => {
     config.resolve.alias.canvas = false;
     return config;
   }
   ```

---

## ⚙️ Environment Configuration

To successfully run this project locally, configure a `.env.local` file inside the root directory containing the following environment variables. 

> [!CAUTION]
> Under no circumstances should these private cloud API credentials and certificates be committed to public Git repositories.

```env
# Cloudinary Storage Configurations
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=your_cloudinary_preset_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Firebase Client configurations
NEXT_PUBLIC_FIREBASE_API_KEY=your_firebase_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_firebase_project_domain.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_firebase_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_firebase_bucket_domain.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_firebase_app_id

# Firebase Admin Configurations (For backend push-notifications & profile controllers)
FIREBASE_CLIENT_EMAIL=your_firebase_admin_client_email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nyour_formatted_private_key\n-----END PRIVATE KEY-----"
```

---

## 🚀 How to Run the Project Locally

### 1. Installation
Clone the project repository to your local system and navigate to the project directory:
```bash
npm install
```

### 2. Launch Development Server
```bash
npm run dev
```
The application will launch on [http://localhost:3000](http://localhost:3000).

### 3. Production Build Compilation & Verification
To test PWA service workers and build optimizations, compile and start a local production instance:
```bash
npm run build
npm run start
```
The server compiles static assets, registers the manifest bundle, and starts a high-performance production server.

---

## 💎 Design and UX System Details

NOTEShub implements beautiful visual designs aligned with premium quality systems:
* **Glassmorphic Elements**: Features high-end light-refracting containers (`bg-background/95 backdrop-blur supports-[backdrop-filter]`) providing sleek backgrounds that blend cleanly with floating gradient background orbs.
* **Animated Themes**: The site's background leverages keyframed Framer Motion orbs that drift and scale dynamically, offering visual depth.
* **Micro-interactions**: Handlers on cards use smooth scale transitions (`whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}`) and sliding transition indicators on sliders (`layoutId="active-tab"`).
* **Loading Skeletons**: Rather than simple spinning icons, pages use structured animated layout skeletons matching the actual components' outlines to make resource fetching load times feel visually instantaneous.

---
*Report compiled on May 26, 2026. Prepared for the NOTEShub Development & Academic Evaluation Committee.*
