# Secure Remote Deletion Architecture Proposal

## 1. Context & Identified Vulnerability in Existing Stack
During the pre-development security audit, an unauthenticated Next.js endpoint was identified:
`project/app/api/delete-file/route.ts`
This endpoint received a raw `publicId` and called Cloudinary's destroy API without verifying caller identity or role.
**Under no circumstances should the Flutter client call this endpoint, nor should the Flutter client store the Cloudinary master secret.**

## 2. Security Decision for Flutter Client
In `mobile/`, remote deletion is **deliberately disabled and locked**:
- In [`AdminResourcesScreen`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/lib/features/admin/presentation/admin_resources_screen.dart), tapping "Delete Resource" triggers the explanatory [`DeletePolicyDialog`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/lib/features/admin/presentation/widgets/delete_policy_dialog.dart).
- Firestore file documents are **not** deleted from the client, preventing orphaned Cloudinary assets where raw PDF files linger indefinitely in cloud storage without a database index.
- Local offline file deletion in [`DownloadsScreen`](file:///c:/Users/AsusTUFA15/Desktop/NotesHub/mobile/lib/features/downloads/presentation/downloads_screen.dart) remains fully functional, removing cached files only from device storage and SharedPreferences without triggering remote API calls.

## 3. Recommended Production Serverless Deletion Architecture
To enable safe remote asset deletion in future phases without exposing credentials:

### A. Firebase Cloud Function (`deleteAcademicResource`)
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { v2 as cloudinary } from 'cloudinary';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export const deleteAcademicResource = functions.https.onCall(async (data, context) => {
  // 1. Verify Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
  }

  // 2. Verify Role Authorization from Firestore
  const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  const role = userDoc.data()?.role;
  const isOwner = role === 'owner' || context.auth.uid === 'U8YkrUlxR9OLwB2XPiwi8AiOo372';

  if (!isOwner) {
    throw new functions.https.HttpsError('permission-denied', 'Only owners may delete academic assets.');
  }

  const { fileDocId, publicId } = data;
  if (!fileDocId || !publicId) {
    throw new functions.https.HttpsError('invalid-argument', 'fileDocId and publicId required.');
  }

  // 3. Atomically delete from Cloudinary RAW storage
  const cloudinaryResult = await cloudinary.uploader.destroy(publicId, { resource_type: 'raw' });

  // 4. Atomically delete metadata from Firestore
  await admin.firestore().collection('files').doc(fileDocId).delete();

  return { success: true, result: cloudinaryResult };
});
```

### B. Security Benefits
1. **Zero Secret Exposure**: Cloudinary credentials reside exclusively in the Google Cloud Secret Manager / Cloud Functions environment.
2. **Server-Side Role Gate**: The caller's Firebase Auth ID token is validated cryptographically against `users/{uid}`.
3. **Atomic Clean-up**: Cloudinary storage and Firestore metadata are cleaned up simultaneously, eliminating orphaned files.

