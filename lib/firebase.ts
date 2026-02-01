import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBHe5Kff_11bMVCkIzAkF6XjXHxb8wGxA0",
  authDomain: "smart-college-notes.firebaseapp.com",
  projectId: "smart-college-notes",
  storageBucket: "smart-college-notes.appspot.com",
  messagingSenderId: "243008726342",
  appId: "1:243008726342:web:52271db2600a071f7a3147",
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

export const auth = getAuth(app);
export const db = getFirestore(app); // 🔴 THIS MUST EXIST

export default app;
