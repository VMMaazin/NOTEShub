"use client";

import { useEffect, useState } from "react";
import {
  doc,
  getDoc,
  setDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext";

type Props = {
  semester: number;
  subject: number;
};

const OWNER_UID = "U8YkrUlxR9OLwB2XPiwi8AiOo372";

export default function EditableSubjectName({
  semester,
  subject,
}: Props) {
  const { user } = useAuth();

  const [name, setName] = useState<string>(`Subject ${subject}`);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [tempName, setTempName] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const docId = `${semester}_${subject}`;
  const isOwner = user?.uid === OWNER_UID;

  // 🔥 Fetch subject name (and auto-create if missing)
  useEffect(() => {
    async function fetchName() {
      try {
        setError(null);

        const ref = doc(db, "subjects", docId);
        const snap = await getDoc(ref);

        if (snap.exists()) {
          setName(snap.data().name);
        } else {
          // Auto-create subject document
          await setDoc(ref, {
            semester,
            subject,
            name: `Subject ${subject}`,
          });

          setName(`Subject ${subject}`);
        }
      } catch (err: any) {
        console.error("Failed to fetch subject name:", err);
        setError(`Failed to load: ${err.message}`);
      } finally {
        setLoading(false);
      }
    }

    fetchName();
  }, [docId, semester, subject]);

  // 🔥 Save renamed subject
  async function saveName() {
    if (!tempName.trim()) {
      setError("Subject name cannot be empty");
      return;
    }

    try {
      setSaving(true);
      setError(null);

      const ref = doc(db, "subjects", docId);

      await setDoc(
        ref,
        {
          semester,
          subject,
          name: tempName.trim(),
          updatedAt: new Date(),
        },
        { merge: true }
      );

      setName(tempName.trim());
      setEditing(false);
    } catch (err: any) {
      console.error("Save error:", err);
      setError(err.message || "Failed to save");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <span className="text-[#8b949e] text-sm">
        Loading…
      </span>
    );
  }

  if (error && !editing) {
    return (
      <div className="text-red-400 text-sm">
        {error}
      </div>
    );
  }

  // ✏️ EDIT MODE
  if (editing && isOwner) {
    return (
      <div className="flex flex-col gap-2">
        <div className="flex items-center gap-2">
          <input
            value={tempName}
            onChange={(e) => setTempName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !saving) saveName();
              if (e.key === "Escape" && !saving) setEditing(false);
            }}
            disabled={saving}
            className="bg-[#0d1117] border border-[#30363d] rounded px-2 py-1 text-sm text-[#c9d1d9] disabled:opacity-50"
            autoFocus
          />
          <button
            onClick={saveName}
            disabled={saving}
            className="text-xs text-[#58a6ff] hover:text-[#79c0ff] disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save"}
          </button>
          <button
            onClick={() => {
              setEditing(false);
              setError(null);
            }}
            disabled={saving}
            className="text-xs text-[#8b949e] hover:text-white disabled:opacity-50"
          >
            Cancel
          </button>
        </div>
        {error && (
          <span className="text-xs text-red-400">{error}</span>
        )}
      </div>
    );
  }

  // 👀 VIEW MODE
  return (
    <div className="flex items-center gap-2">
      <h1 className="text-2xl font-bold text-[#c9d1d9]">
        {name}
      </h1>

      {isOwner && (
        <button
          onClick={() => {
            setTempName(name);
            setEditing(true);
            setError(null);
          }}
          className="text-sm text-[#8b949e] hover:text-[#58a6ff]"
          title="Edit subject name"
        >
          ✏️
        </button>
      )}
    </div>
  );
}
