"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { useEffect, useState } from "react";
import {
  collection,
  getDocs,
  query,
  where,
  updateDoc,
  doc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import FileList from "@/components/FileList";
import UploadFile from "@/components/UploadFile";
import { useAuth } from "@/context/AuthContext";

export default function SubjectPage() {
  const params = useParams();
  const subjectId = Number(params.subjectId);
  const { role } = useAuth();

  const isAuthor = role === "author" || role === "owner";

  const [subjectName, setSubjectName] = useState("");
  const [editing, setEditing] = useState(false);
  const [newName, setNewName] = useState("");
  const [subjectDocId, setSubjectDocId] = useState<string | null>(null);

  useEffect(() => {
    async function fetchSubject() {
      const q = query(
        collection(db, "subjects"),
        where("semester", "==", 4),
        where("subject", "==", subjectId)
      );

      const snap = await getDocs(q);

      if (!snap.empty) {
        const docSnap = snap.docs[0];
        setSubjectDocId(docSnap.id);
        setSubjectName(docSnap.data().name);
        setNewName(docSnap.data().name);
      } else {
        setSubjectName(`Subject ${subjectId}`);
        setNewName(`Subject ${subjectId}`);
      }
    }

    fetchSubject();
  }, [subjectId]);

  async function saveName() {
    if (!subjectDocId || !newName.trim()) return;

    await updateDoc(doc(db, "subjects", subjectDocId), {
      name: newName.trim(),
    });

    setSubjectName(newName.trim());
    setEditing(false);
  }

  return (
    <main className="max-w-7xl mx-auto px-6 py-10 space-y-8">
      {/* Back */}
      {/* Back */}
      <Link
        href="/semester/4"
        className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-secondary/50 text-secondary-foreground hover:bg-secondary transition-all hover:-translate-x-1 group text-sm font-medium"
      >
        <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-1" />
        Back to Subjects
      </Link>

      {/* Subject title */}
      <div className="flex items-center gap-3">
        {editing ? (
          <>
            <input
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              className="bg-background border border-border rounded px-2 py-1 text-xl font-bold"
            />
            <button
              onClick={saveName}
              className="text-sm text-green-500 hover:underline"
            >
              Save
            </button>
            <button
              onClick={() => {
                setEditing(false);
                setNewName(subjectName);
              }}
              className="text-sm text-muted-foreground hover:underline"
            >
              Cancel
            </button>
          </>
        ) : (
          <>
            <h1 className="text-3xl font-bold">
              {subjectName || "Loading…"}
            </h1>
            {isAuthor && (
              <button
                onClick={() => setEditing(true)}
                className="text-sm text-primary hover:underline"
                title="Rename subject"
              >
                ✏️
              </button>
            )}
          </>
        )}
      </div>

      {/* MODULES */}
      {[1, 2, 3, 4, 5].map((module) => (
        <div
          key={module}
          className="rounded-lg border border-border p-5 space-y-4"
        >
          <h2 className="text-lg font-semibold">
            Module {module}
          </h2>

          {/* NOTES */}
          <section>
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-medium">Notes</h3>
              {isAuthor && (
                <UploadFile
                  semester={4}
                  subject={subjectId}
                  module={module}
                  type="notes"
                />
              )}
            </div>
            <FileList
              semester={4}
              subject={subjectId}
              module={module}
              type="notes"
            />
          </section>

          {/* QUESTION BANK */}
          <section>
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-medium">Question Bank</h3>
              {isAuthor && (
                <UploadFile
                  semester={4}
                  subject={subjectId}
                  module={module}
                  type="qbank"
                />
              )}
            </div>
            <FileList
              semester={4}
              subject={subjectId}
              module={module}
              type="qbank"
            />
          </section>

          {/* EXTRA */}
          <section>
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-medium">Extra Resources</h3>
              {isAuthor && (
                <UploadFile
                  semester={4}
                  subject={subjectId}
                  module={module}
                  type="extra"
                />
              )}
            </div>
            <FileList
              semester={4}
              subject={subjectId}
              module={module}
              type="extra"
            />
          </section>
        </div>
      ))}
    </main>
  );
}
