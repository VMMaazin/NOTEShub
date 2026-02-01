"use client";

import { useEffect, useState } from "react";
import {
  collection,
  query,
  where,
  onSnapshot,
  deleteDoc,
  doc,
  updateDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import dynamic from "next/dynamic";
import { useAuth } from "@/context/AuthContext";

const PdfViewer = dynamic(() => import("./PdfViewer"), {
  ssr: false,
});

type Props = {
  semester: number;
  subject: number;
  module: number;
  type: "notes" | "qbank" | "extra";
};

type FileItem = {
  id: string;
  name: string;
  url: string;
  publicId: string;
};

export default function FileList({
  semester,
  subject,
  module,
  type,
}: Props) {
  const [files, setFiles] = useState<FileItem[]>([]);
  const [activePdf, setActivePdf] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [newName, setNewName] = useState("");

  const { role } = useAuth();
  const isAuthor = role === "author" || role === "owner";

  useEffect(() => {
    const q = query(
      collection(db, "files"),
      where("semester", "==", semester),
      where("subject", "==", subject),
      where("module", "==", module),
      where("type", "==", type)
    );

    const unsub = onSnapshot(q, (snapshot) => {
      const list: FileItem[] = [];
      snapshot.forEach((docSnap) => {
        const data = docSnap.data();
        list.push({
          id: docSnap.id,
          name: data.name,
          url: data.url,
          publicId: data.publicId,
        });
      });
      setFiles(list);
    });

    return () => unsub();
  }, [semester, subject, module, type]);

  async function handleDelete(file: FileItem) {
    if (!confirm("Delete this file permanently?")) return;

    await fetch("/api/delete-file", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ publicId: file.publicId }),
    });

    await deleteDoc(doc(db, "files", file.id));
  }

  async function handleRename(file: FileItem) {
    if (!newName.trim()) return;

    await updateDoc(doc(db, "files", file.id), {
      name: newName.trim(),
    });

    setEditingId(null);
    setNewName("");
  }

  if (files.length === 0) {
    return (
      <p className="text-xs text-[#8b949e]">
        No files uploaded yet.
      </p>
    );
  }

  return (
    <>
      <ul className="space-y-2">
        {files.map((file) => (
          <li
            key={file.id}
            className="flex items-center justify-between px-3 py-2 border border-[#30363d] rounded-md bg-[#0d1117]"
          >
            {editingId === file.id ? (
              <input
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") handleRename(file);
                  if (e.key === "Escape") setEditingId(null);
                }}
                className="bg-[#161b22] border border-[#30363d] px-2 py-1 text-sm rounded w-full mr-4"
                autoFocus
              />
            ) : (
              <span className="text-sm truncate">
                {file.name}
              </span>
            )}

            <div className="flex gap-3 text-xs">
              <button
                onClick={() => setActivePdf(file.url)}
                className="text-[#58a6ff] hover:underline"
              >
                View
              </button>

              <a
                href={file.url}
                download
                className="text-[#58a6ff] hover:underline"
              >
                Download
              </a>

              {isAuthor && (
                <>
                  {editingId !== file.id && (
                    <button
                      onClick={() => {
                        setEditingId(file.id);
                        setNewName(file.name);
                      }}
                      className="text-[#58a6ff] hover:underline"
                    >
                      Rename
                    </button>
                  )}

                  <button
                    onClick={() => handleDelete(file)}
                    className="text-red-400 hover:underline"
                  >
                    Delete
                  </button>
                </>
              )}
            </div>
          </li>
        ))}
      </ul>

      {activePdf && (
        <PdfViewer
          url={activePdf}
          onClose={() => setActivePdf(null)}
        />
      )}
    </>
  );
}
