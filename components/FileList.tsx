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
import { Eye, Download, FileQuestion } from "lucide-react";
// Removed dynamic import of PdfViewer
// Removed dynamic import of PdfViewer
import { useAuth } from "@/context/AuthContext";
import DownloadModal from "./DownloadModal";
import PdfViewerModal from "./PdfViewerModal";
import { motion, Variants } from "framer-motion";
import { toast } from "sonner";
import { Skeleton } from "@/components/ui/skeleton";

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
  },
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 15 },
  visible: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 24 } },
};

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
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [newName, setNewName] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [downloadingFile, setDownloadingFile] = useState<FileItem | null>(null);
  const [viewingFile, setViewingFile] = useState<FileItem | null>(null);

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
      setLoading(false);
    });

    return () => unsub();
  }, [semester, subject, module, type]);

  async function handleDelete(file: FileItem) {
    if (!confirm("Delete this file permanently?")) return;

    try {
      // Delete from Cloudinary
      await fetch("/api/delete-file", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicId: file.publicId }),
      });

      // Delete from Firestore
      await deleteDoc(doc(db, "files", file.id));
      toast.success("File deleted successfully!");
    } catch (err) {
      console.error("Delete error:", err);
      toast.error("Failed to delete file.");
    }
  }

  async function handleRename(file: FileItem) {
    if (!newName.trim()) {
      toast.error("File name cannot be empty");
      return;
    }

    try {
      setSaving(true);

      console.log("Attempting to rename file:", file.id);
      console.log("New name:", newName.trim());

      await updateDoc(doc(db, "files", file.id), {
        name: newName.trim(),
      });

      console.log("Rename successful!");
      toast.success("File renamed successfully!");
      setEditingId(null);
      setNewName("");
    } catch (err: any) {
      console.error("Rename error:", err);
      toast.error(`Failed to rename: ${err.message || "Unknown error"}`);
    } finally {
      setSaving(false);
    }
  }

  function startEditing(file: FileItem) {
    setEditingId(file.id);
    setNewName(file.name);
  }

  function cancelEditing() {
    setEditingId(null);
    setNewName("");
  }

  function openPdf(file: FileItem) {
    // If it's a PDF, we can use our viewer
    if (file.url.toLowerCase().includes('.pdf') || file.url.toLowerCase().includes('cloudinary')) {
      setViewingFile(file);
    } else {
      // Fallback for other file types
      window.open(file.url, "_blank", "noopener,noreferrer");
    }
  }

  if (loading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} className="h-16 w-full" />
        ))}
      </div>
    );
  }

  if (files.length === 0) {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="flex flex-col items-center justify-center p-8 text-center bg-card/30 border border-dashed rounded-xl"
      >
        <div className="p-3 bg-muted rounded-full mb-3">
          <FileQuestion className="w-6 h-6 text-muted-foreground" />
        </div>
        <h4 className="font-medium text-foreground mb-1">No files yet</h4>
        <p className="text-sm text-muted-foreground max-w-[280px] sm:max-w-sm">
          There are no uploaded documents for this section at the moment.
        </p>
      </motion.div>
    );
  }

  return (
    <>

      <motion.ul
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="space-y-3"
      >
        {files.map((file) => (
          <motion.li
            variants={itemVariants}
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
              <div className="text-sm truncate font-medium flex-1 min-w-0">
                {file.name}
              </div>
            )}

            {editingId !== file.id && (
              <div className="grid grid-cols-2 sm:flex sm:flex-wrap gap-2 sm:gap-3 text-xs w-full sm:w-auto mt-2 sm:mt-0">
                {/* View */}
                <button
                  onClick={() => openPdf(file)}
                  className="inline-flex justify-center items-center gap-2 px-4 py-2.5 rounded-lg border border-primary text-primary hover:bg-primary/10 transition font-medium text-sm group w-full sm:w-auto"
                >
                  <Eye className="w-4 h-4" />
                  View
                </button>

                {/* Download Button triggering Modal */}
                <button
                  onClick={() => setDownloadingFile(file)}
                  className="inline-flex justify-center items-center gap-2 px-4 py-2.5 rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 transition font-medium text-sm shadow-sm hover:shadow w-full sm:w-auto"
                >
                  <Download className="w-4 h-4" />
                  Download
                </button>

                {isAuthor && (
                  <>
                    <button
                      onClick={() => startEditing(file)}
                      className="px-3 py-1.5 rounded-md border border-border text-muted-foreground hover:text-foreground hover:border-foreground/50 transition w-full sm:w-auto flex justify-center items-center"
                    >
                      Rename
                    </button>

                    <button
                      onClick={() => handleDelete(file)}
                      className="px-3 py-1.5 rounded-md border border-red-500 text-red-500 hover:bg-red-500/10 transition w-full sm:w-auto flex justify-center items-center"
                    >
                      Delete
                    </button>
                  </>
                )}
              </div>
            )}
          </motion.li>
        ))}
      </motion.ul>

      {/* Download Modal - Pass enriched file object */}
      {downloadingFile && (
        <DownloadModal
          isOpen={!!downloadingFile}
          onClose={() => setDownloadingFile(null)}
          file={{
            ...downloadingFile,
            semester,
            subject,
            module,
            type
          }}
        />
      )}

      {/* PDF Viewer Viewer Modal */}
      {viewingFile && (
        <PdfViewerModal
          isOpen={!!viewingFile}
          onClose={() => setViewingFile(null)}
          fileUrl={viewingFile.url}
          fileName={viewingFile.name}
        />
      )}
    </>
  );
}
