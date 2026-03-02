"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, Book, ShieldQuestion, FileText } from "lucide-react";
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
import { motion, AnimatePresence } from "framer-motion";

export default function SubjectPage() {
  const params = useParams();
  const subjectId = Number(params.subjectId);
  const { role } = useAuth();

  const isAuthor = role === "author" || role === "owner";

  const [subjectName, setSubjectName] = useState("");
  const [editing, setEditing] = useState(false);
  const [newName, setNewName] = useState("");
  const [subjectDocId, setSubjectDocId] = useState<string | null>(null);
  const [activeModule, setActiveModule] = useState(1);

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
    <main className="w-full min-w-0 max-w-7xl mx-auto px-4 sm:px-6 py-6 sm:py-10 space-y-6 sm:space-y-8 overflow-hidden">
      {/* Back */}
      <motion.div
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.3 }}
      >
        <Link
          href="/semester/4"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-secondary/50 text-secondary-foreground hover:bg-secondary transition-all hover:-translate-x-1 group text-sm font-medium"
        >
          <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-1" />
          Back to Subjects
        </Link>
      </motion.div>

      {/* Subject title */}
      <motion.div
        className="flex items-start sm:items-center gap-3 w-full"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.1 }}
      >
        {editing ? (
          <>
            <input
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              className="bg-background border border-border rounded px-2 py-1 text-xl font-bold focus:outline-none focus:ring-2 focus:ring-primary"
              autoFocus
            />
            <button
              onClick={saveName}
              className="text-sm text-green-500 hover:text-green-600 font-medium"
            >
              Save
            </button>
            <button
              onClick={() => {
                setEditing(false);
                setNewName(subjectName);
              }}
              className="text-sm text-muted-foreground hover:text-foreground font-medium"
            >
              Cancel
            </button>
          </>
        ) : (
          <>
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight break-words min-w-0 flex-1">
              {subjectName || "Loading…"}
            </h1>
            {isAuthor && (
              <button
                onClick={() => setEditing(true)}
                className="text-sm px-2 py-1 rounded-md text-primary hover:bg-primary/10 transition-colors"
                title="Rename subject"
              >
                ✏️
              </button>
            )}
          </>
        )}
      </motion.div>

      {/* MODULES TABS */}
      <motion.div
        className="w-full overflow-x-auto pb-2 scrollbar-none mb-8 sm:mb-10"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.2 }}
      >
        <div className="flex bg-secondary/40 p-1.5 rounded-2xl border border-border/20 w-max shadow-inner mx-auto sm:mx-0">
          {[1, 2, 3, 4, 5].map((module) => {
            const isActive = activeModule === module;
            return (
              <button
                key={module}
                onClick={() => setActiveModule(module)}
                className={`relative px-6 py-2.5 rounded-xl text-sm font-semibold transition-colors duration-300 whitespace-nowrap ${isActive
                  ? "text-foreground"
                  : "text-muted-foreground hover:text-foreground hover:bg-secondary/50"
                  }`}
              >
                {isActive && (
                  <motion.div
                    layoutId="active-tab"
                    className="absolute inset-0 bg-background rounded-xl shadow-sm border border-border/50"
                    transition={{ type: "spring", stiffness: 300, damping: 25 }}
                  />
                )}
                <span className="relative z-10">Module {module}</span>
              </button>
            );
          })}
        </div>
      </motion.div>

      {/* ACTIVE MODULE CONTENT */}
      <AnimatePresence mode="wait">
        <motion.div
          key={activeModule}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.3 }}
          className="space-y-12"
        >
          {/* NOTES */}
          <section>
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-blue-500/10 text-blue-500">
                  <Book className="w-5 h-5" />
                </div>
                <h2 className="text-xl sm:text-2xl font-bold">Notes</h2>
              </div>
              {isAuthor && (
                <UploadFile
                  semester={4}
                  subject={subjectId}
                  module={activeModule}
                  type="notes"
                />
              )}
            </div>
            <FileList
              semester={4}
              subject={subjectId}
              module={activeModule}
              type="notes"
            />
          </section>

          {/* QUESTION BANK */}
          <section>
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-indigo-500/10 text-indigo-500">
                  <ShieldQuestion className="w-5 h-5" />
                </div>
                <h2 className="text-xl sm:text-2xl font-bold">Question Banks</h2>
              </div>
              {isAuthor && (
                <UploadFile
                  semester={4}
                  subject={subjectId}
                  module={activeModule}
                  type="qbank"
                />
              )}
            </div>
            <FileList
              semester={4}
              subject={subjectId}
              module={activeModule}
              type="qbank"
            />
          </section>

          {/* EXTRA */}
          <section>
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-500">
                  <FileText className="w-5 h-5" />
                </div>
                <h2 className="text-xl sm:text-2xl font-bold">Extra Resources</h2>
              </div>
              {isAuthor && (
                <UploadFile
                  semester={4}
                  subject={subjectId}
                  module={activeModule}
                  type="extra"
                />
              )}
            </div>
            <FileList
              semester={4}
              subject={subjectId}
              module={activeModule}
              type="extra"
            />
          </section>
        </motion.div>
      </AnimatePresence>
    </main>
  );
}
