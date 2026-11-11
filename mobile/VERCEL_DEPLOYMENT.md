# NOTEShub — Vercel Web Deployment Guide

This guide explains how to deploy the NOTEShub Flutter Web application (`mobile/`) to **Vercel** as a dedicated, standalone project, without disturbing the existing Next.js web application (`project/`).

---

## 1. Architecture & Isolation Architecture

The repository contains two distinct applications:
- `project/`: The existing Next.js web application currently deployed in production. **Do not modify or delete this directory.**
- `mobile/`: The high-performance Flutter application with Royal Academic Glassmorphism, optimized for both Android and Web.

To deploy the Flutter Web application safely without impacting the existing Next.js production website:
1. Create a **separate, new project** in the Vercel Dashboard.
2. Link the repository to this new project with **Root Directory** set to `mobile`.
3. Use a separate domain or preview URL (`*.vercel.app`) until you choose to switch your primary domain.

---

## 2. Vercel Project Dashboard Configuration

When importing or creating the project in the [Vercel Dashboard](https://vercel.com):

| Setting | Value | Notes |
| :--- | :--- | :--- |
| **Project Name** | `noteshub-flutter` (or `noteshub-web`) | Choose an independent name from your existing Next.js project. |
| **Framework Preset** | `Other` | Flutter is not a standard Node.js framework; selecting `Other` gives full control over the build. |
| **Root Directory** | `mobile` | **Critical**: Tells Vercel to run commands inside `mobile/` rather than the repository root. |
| **Build Command** | `bash scripts/build_vercel.sh` | Executes the automated SDK installer & build script. Toggle "Override" to **ON**. |
| **Output Directory** | `build/web` | Location where Flutter Web outputs static assets. Toggle "Override" to **ON**. |
| **Install Command** | *(Leave empty)* | Turn "Override" **ON** and leave the text field empty. Vercel should not run `npm install`. |

---

## 3. How the Automated Build Script Works (`scripts/build_vercel.sh`)

Vercel's default Linux build environment does not include the Flutter SDK. The included shell script (`mobile/scripts/build_vercel.sh`) provides zero-config automated setup:

1. **Flutter SDK Detection**:
   - Checks if `flutter` is already present in `PATH`.
   - If not present, it performs a lightweight shallow clone of Flutter's `stable` channel into `${HOME}/flutter`:
     ```bash
     git clone https://github.com/flutter/flutter.git --depth 1 -b stable "${HOME}/flutter"
     export PATH="${PATH}:${HOME}/flutter/bin"
     ```
2. **Environment Configuration**:
   - Enables web support and disables telemetry prompts:
     ```bash
     flutter config --enable-web --no-analytics
     ```
3. **Dependency Resolution**:
   - Resolves all Dart/Flutter packages:
     ```bash
     flutter pub get
     ```
4. **Release Compilation**:
   - Builds the production web bundle with a root base href:
     ```bash
     flutter build web --release --base-href /
     ```
5. **Artifact Validation**:
   - Asserts that `build/web/index.html` exists before finishing.

---

## 4. SPA Routing & Caching Configuration (`vercel.json`)

Flutter Web uses client-side routing. To ensure direct URL navigation and page reloads work seamlessly without returning HTTP 404 errors, `mobile/vercel.json` provides:

### Single Page Application (SPA) Rewrites
```json
"rewrites": [
  {
    "source": "/(.*)",
    "destination": "/index.html"
  }
]
```
- When a user refreshes `/semester/4`, `/semester/5`, or `/downloads`, Vercel serves `/index.html` and lets Flutter's router handle the view.

### Cache Strategy
```json
"headers": [
  {
    "source": "/index.html",
    "headers": [
      {
        "key": "Cache-Control",
        "value": "no-cache, no-store, must-revalidate"
      }
    ]
  },
  {
    "source": "/(.*)\\.(js|css|wasm|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)",
    "headers": [
      {
        "key": "Cache-Control",
        "value": "public, max-age=31536000, immutable"
      }
    ]
  }
]
```
- **`index.html`**: Never cached stale; users immediately receive new releases without manual browser hard refreshes.
- **Static Assets (`main.dart.js`, WASM, Fonts, Images)**: Cached with `immutable` for 1 year for lightning-fast page transitions and minimal bandwidth usage.

---

## 5. Web Assets & Security Audit

- **`<base href="/">`**: Configured in `mobile/web/index.html` via `$FLUTTER_BASE_HREF` (set to `/` by the build command).
- **Branding & PWA**:
  - `mobile/web/manifest.json` configured with NOTEShub metadata, Royal Gold theme color (`#C5A04A`), and Midnight Navy Dark background (`#090F22`).
  - Web favicon and high-resolution icons are linked properly.
- **Firebase Security**:
  - Web Firebase options in `mobile/lib/firebase_options.dart` use public Firebase API keys (`AIzaSyBHe5Kff_...`).
  - Firebase API keys identify the project to Google servers and are intended to be public in client apps; authorization and data protection are strictly enforced by Firestore Security Rules and Firebase Auth.
  - No secret tokens, service account credentials, or Cloudinary API secrets are exposed in the client code.

---

## 6. Testing the Build Locally

Before deploying to Vercel, you can test the release build locally:

### Option A: Flutter Command
```bash
cd mobile
flutter build web --release
```

### Option B: Local HTTP Server
To preview the compiled release output exactly as Vercel will serve it:
```bash
cd mobile/build/web
python -m http.server 8080
```
Open `http://localhost:8080` in your web browser.

---

## 7. Safely Switching Domains (When Ready)

When you are ready to transition your live domain from the Next.js project to the Flutter Web application:
1. Go to your existing Next.js Vercel project > **Settings** > **Domains**.
2. Note your custom domain (e.g., `noteshub.in`).
3. Remove or reassign the domain from the Next.js project.
4. Go to your new `noteshub-flutter` Vercel project > **Settings** > **Domains**.
5. Add your custom domain. Vercel automatically generates SSL certificates and begins routing live traffic to the Flutter Web application.

