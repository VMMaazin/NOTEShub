// ... (imports remain)
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
// Removed dynamic import of PdfViewer
import { useAuth } from "@/context/AuthContext";

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

// ✅ Force Cloudinary download
function getDownloadUrl(url: string) {
  return url.replace("/upload/", "/upload/fl_attachment/");
}

export default function FileList({
  semester,
  subject,
  module,
  type,
}: Props) {
  const [files, setFiles] = useState<FileItem[]>([]);
  // Removed activePdf state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [newName, setNewName] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { role, user } = useAuth();
  const isAuthor = role === "author" || role === "owner";

  // Debug logging
  useEffect(() => {
    console.log("FileList - User role:", role);
    console.log("FileList - Is author:", isAuthor);
    console.log("FileList - User:", user);
  }, [role, isAuthor, user]);

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

    try {
      setError(null);

      // Delete from Cloudinary
      await fetch("/api/delete-file", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicId: file.publicId }),
      });

      // Delete from Firestore
      await deleteDoc(doc(db, "files", file.id));
    } catch (err) {
      console.error("Delete error:", err);
      setError("Failed to delete file. Check console for details.");
    }
  }

  async function handleRename(file: FileItem) {
    if (!newName.trim()) {
      setError("File name cannot be empty");
      return;
    }

    try {
      setSaving(true);
      setError(null);

      console.log("Attempting to rename file:", file.id);
      console.log("New name:", newName.trim());

      await updateDoc(doc(db, "files", file.id), {
        name: newName.trim(),
      });

      console.log("Rename successful!");
      setEditingId(null);
      setNewName("");
    } catch (err: any) {
      console.error("Rename error:", err);
      setError(`Failed to rename: ${err.message || "Unknown error"}`);
    } finally {
      setSaving(false);
    }
  }

  function startEditing(file: FileItem) {
    setEditingId(file.id);
    setNewName(file.name);
    setError(null);
  }

  function cancelEditing() {
    setEditingId(null);
    setNewName("");
    setError(null);
  }

  function openPdf(url: string) {
    window.open(url, "_blank", "noopener,noreferrer");
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
      {/* Error message */}
      {error && (
        <div className="mb-4 p-3 bg-red-900/20 border border-red-500 rounded text-red-400 text-sm">
          {error}
        </div>
      )}

      <ul className="space-y-3">
        {files.map((file) => (
          <li
            key={file.id}
            className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-4 py-3 border border-border rounded-md bg-card/50 hover:bg-card/80 transition-colors"
          >
            {/* File name */}
            {editingId === file.id ? (
              <div className="flex items-center gap-2 flex-1">
                <input
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !saving) handleRename(file);
                    if (e.key === "Escape") cancelEditing();
                  }}
                  disabled={saving}
                  className="bg-background border border-input px-2 py-1 text-sm rounded flex-1 disabled:opacity-50"
                  autoFocus
                />
                <button
                  onClick={() => handleRename(file)}
                  disabled={saving}
                  className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                >
                  {saving ? "Saving..." : "Save"}
                </button>
                <button
                  onClick={cancelEditing}
                  disabled={saving}
                  className="px-2 py-1 text-xs border border-border text-muted-foreground rounded hover:text-foreground disabled:opacity-50"
                >
                  Cancel
                </button>
              </div>
            ) : (
              <span className="text-sm truncate font-medium">
                {file.name}
              </span>
            )}

            {/* Actions */}
            {editingId !== file.id && (
              <div className="flex flex-wrap gap-2 text-xs">
                {/* View */}
                <button
                  onClick={() => openPdf(file.url)}
                  className="px-3 py-1.5 rounded-md border border-primary text-primary hover:bg-primary/10 transition font-medium"
                >
                  View
                </button>

                {/* Download */}
                <a
                  href={getDownloadUrl(file.url)}
                  className="px-3 py-1.5 rounded-md bg-primary text-primary-foreground hover:bg-primary/90 transition font-medium"
                >
                  Download
                </a>

                {isAuthor && (
                  <>
                    <button
                      onClick={() => startEditing(file)}
                      className="px-3 py-1.5 rounded-md border border-border text-muted-foreground hover:text-foreground hover:border-foreground/50 transition"
                    >
                      Rename
                    </button>

                    <button
                      onClick={() => handleDelete(file)}
                      className="px-3 py-1.5 rounded-md border border-red-500 text-red-500 hover:bg-red-500/10 transition"
                    >
                      Delete
                    </button>
                  </>
                )}
              </div>
            )}
          </li>
        ))}
      </ul>
    </>
  );
}
