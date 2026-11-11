"use client";

import { useState } from "react";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";

type Props = {
  semester: number;
  subject: number; // ✅ NUMBER, not string
  module: number;
  type: "notes" | "qbank" | "extra";
};

// ✅ Cloudinary config
const CLOUDINARY_UPLOAD_PRESET = "college_notes";
const CLOUDINARY_CLOUD_NAME = "debfdnujc";

export default function UploadFile({
  semester,
  subject,
  module,
  type,
}: Props) {
  const [uploading, setUploading] = useState(false);

  async function handleUpload(
    e: React.ChangeEvent<HTMLInputElement>
  ) {
    const file = e.target.files?.[0];
    if (!file) return;

    // 🛑 SAFETY CHECK (prevents Firestore undefined error)
    if (
      semester === undefined ||
      subject === undefined ||
      module === undefined ||
      !type
    ) {
      alert("Invalid upload context");
      return;
    }

    setUploading(true);

    try {
      const formData = new FormData();
      formData.append("file", file);
      formData.append("upload_preset", CLOUDINARY_UPLOAD_PRESET);

      // ✅ RAW upload (PDF-safe)
      const res = await fetch(
        `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/raw/upload`,
        {
          method: "POST",
          body: formData,
        }
      );

      const data = await res.json();

      if (!data.secure_url) {
        throw new Error("Cloudinary upload failed");
      }

      // ✅ Firestore document (MATCHES queries exactly)
      await addDoc(collection(db, "files"), {
        semester,
        subject, // ✅ SAME FIELD USED IN where()
        module,
        type,
        name: file.name,
        url: data.secure_url,
        publicId: data.public_id,
        createdAt: serverTimestamp(),
      });

      e.target.value = "";
    } catch (err) {
      console.error("Upload failed:", err);
      alert("Upload failed. Check console.");
    } finally {
      setUploading(false);
    }
  }

  return (
    <label className="inline-block text-xs text-[#58a6ff] cursor-pointer hover:underline">
      {uploading ? "Uploading…" : "Upload"}
      <input
        type="file"
        accept=".pdf,.doc,.docx,.ppt,.pptx,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-powerpoint,application/vnd.openxmlformats-officedocument.presentationml.presentation"
        hidden
        onChange={handleUpload}
        disabled={uploading}
      />
    </label>
  );
}
