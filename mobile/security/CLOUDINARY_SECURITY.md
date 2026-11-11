# Cloudinary Security Architecture & Dashboard Hardening Guide

## 1. Overview
NOTEShub stores study PDFs directly in Cloudinary RAW storage (`resource_type: raw`).
In the Flutter mobile and web clients, uploads are performed directly to Cloudinary using an **unsigned upload preset** (`college_notes`) on cloud `debfdnujc`.

## 2. Security Boundaries & Zero-Secret Guarantee
- **No Private Secrets in Client**: The client application **never** stores or references `CLOUDINARY_API_KEY` or `CLOUDINARY_API_SECRET`.
- **Pre-Upload Client Validation**:
  - **MIME & Extension Enforcement**: Only `.pdf` filenames are accepted.
  - **Magic Byte Inspection**: The first bytes of the file are checked for `%PDF-` (`0x25, 0x50, 0x44, 0x46, 0x2D`). Any renamed executables, scripts, or images are rejected before any network traffic is initiated.
  - **Size Ceiling**: Uploads exceeding 50 MB are blocked on the client device.
- **Atomic Rollback & Recovery Strategy**:
  - If a network error interrupts a transfer, the Dio `CancelToken` aborts the multipart stream.
  - If Cloudinary returns a success response (`secure_url` and `public_id`) but saving metadata to Firestore fails (e.g. Firestore network timeout), the client caches the upload result and offers a "Retry Save" action without re-uploading the file.
  - The client **does not** attempt remote Cloudinary asset deletion during rollback, preventing accidental orphaned deletions or exploitation.

## 3. Recommended Cloudinary Console / Dashboard Restrictions
Administrators should configure the following settings in the Cloudinary Console (`Settings > Upload > Upload presets > college_notes`):

1. **Preset Mode**:
   - Mode: `Unsigned`
   - Allowed formats: `pdf` only.
2. **File Size Limit**:
   - Max file size: `52428800` bytes (50 MB).
3. **Resource Type**:
   - Strictly restrict to `raw`.
4. **Access Control & Delivery**:
   - Access Mode: `Public` (read-only for student PDF viewing).
   - Delivery Type: `upload`.
5. **Auto-tagging & Folder**:
   - Folder: `academic_notes/` or root namespace.
6. **Overwrite Prevention**:
   - Enable `Use filename or unique suffix` (Cloudinary assigns unique hashes to avoid collisions).

## 4. Remote Asset Deletion Policy
- Cloudinary asset deletion (`/v1_1/:cloud_name/raw/destroy`) strictly requires basic auth using the Cloudinary API Secret or a signed timestamp signature.
- **Under no circumstances should the client app hold the API Secret.**
- Remote deletion is deliberately locked in the client application until an authenticated Firebase Cloud Function is deployed (see `mobile/security/SECURE_DELETION_PROPOSAL.md`).

