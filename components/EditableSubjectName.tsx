"use client";

import { useEffect, useState } from "react";
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext"; // adjust if your path differs

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

  const docId = `${semester}_${subject}`;

  useEffect(() => {
    async function fetchName() {
      try {
        const ref = doc(db, "subjects", docId);
        const snap = await getDoc(ref);

        if (snap.exists()) {
          setName(snap.data().name);
        }
      } catch (err) {
        console.error("Failed to fetch subject name", err);
      } finally {
        setLoading(false);
      }
    }

    fetchName();
  }, [docId]);

  async function saveName() {
    if (!tempName.trim()) return;

    const ref = doc(db, "subjects", docId);

    await setDoc(
      ref,
      {
        semester,
        subject,
        name: tempName.trim(),
      },
      { merge: true }
    );

    setName(tempName.trim());
    setEditing(false);
  }

  if (loading) {
    return (
      <span className="text-[#8b949e] text-sm">
        Loading…
      </span>
    );
  }

  // EDIT MODE
  if (editing && user?.uid === OWNER_UID) {
    return (
      <div className="flex items-center gap-2">
        <input
          value={tempName}
          onChange={(e) => setTempName(e.target.value)}
          className="bg-[#0d1117] border border-[#30363d] rounded px-2 py-1 text-sm text-[#c9d1d9]"
          autoFocus
        />
        <button
          onClick={saveName}
          className="text-xs text-[#58a6ff]"
        >
          Save
        </button>
        <button
          onClick={() => setEditing(false)}
          className="text-xs text-[#8b949e]"
        >
          Cancel
        </button>
      </div>
    );
  }

  // VIEW MODE
  return (
    <div className="flex items-center gap-2">
      <h1 className="text-2xl font-bold text-[#c9d1d9]">
        {name}
      </h1>

      {user?.uid === OWNER_UID && (
        <button
          onClick={() => {
            setTempName(name);
            setEditing(true);
          }}
          className="text-sm text-[#8b949e] hover:text-[#58a6ff]"
        >
          ✏️
        </button>
      )}
    </div>
  );
}
