"use client";

import { useState, useEffect, useRef } from "react";
import { collection, getDocs, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Search, FileText, Book, ShieldQuestion, Download, Eye, Loader2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import PdfViewerModal from "@/components/PdfViewerModal";
import DownloadModal from "@/components/DownloadModal";

type Subject = {
  subject: number;
  name: string;
};

type FileItem = {
  id: string;
  name: string;
  url: string;
  publicId: string;
  semester: number;
  subject: number;
  module: number;
  type: "notes" | "qbank" | "extra";
};

// Generates acronym like "Web Technology" -> "WT"
function getAcronym(name: string) {
  return name
    .split(/\s+/)
    .map((word) => word[0])
    .join("")
    .toLowerCase();
}

export default function HomeSearch() {
  const [query, setQuery] = useState("");
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [files, setFiles] = useState<FileItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasFetched, setHasFetched] = useState(false);
  
  const [viewingFile, setViewingFile] = useState<FileItem | null>(null);
  const [downloadingFile, setDownloadingFile] = useState<FileItem | null>(null);

  // Debounce actual search execution
  useEffect(() => {
    if (!query.trim()) return;
    
    if (!hasFetched) {
      setLoading(true);
      Promise.all([
        getDocs(collection(db, "subjects")),
        getDocs(collection(db, "files"))
      ]).then(([subjectsSnap, filesSnap]) => {
        const subjectsList: Subject[] = subjectsSnap.docs.map((d) => ({
          subject: d.data().subject,
          name: d.data().name
        }));
        setSubjects(subjectsList);

        const filesList: FileItem[] = filesSnap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            name: data.name,
            url: data.url,
            publicId: data.publicId,
            semester: data.semester,
            subject: data.subject,
            module: data.module,
            type: data.type
          };
        });
        setFiles(filesList);
        setHasFetched(true);
      }).catch(console.error)
      .finally(() => setLoading(false));
    }
  }, [query, hasFetched]);

  // Execute Search
  const searchResults = () => {
    if (!query.trim()) return [];
    
    const lowerQuery = query.toLowerCase();
    
    // Split the query into terms. 
    // Examples: "wt mod 2", "web technology module 1 notes", "os 3"
    const terms = lowerQuery.split(/\s+/).filter(Boolean);

    return files.filter((file) => {
      const subject = subjects.find((s) => s.subject === file.subject);
      const subjectName = subject?.name.toLowerCase() || "";
      const subjectAcronym = subject ? getAcronym(subject.name) : "";
      
      const fileName = file.name.toLowerCase();
      const typeStr = file.type.toLowerCase();
      const moduleStr = `module ${file.module} mod ${file.module} ${file.module}`;

      // Check if ALL terms are present in at least ONE of the file's text properties
      return terms.every((term) => {
        return (
          fileName.includes(term) ||
          subjectName.includes(term) ||
          subjectAcronym.includes(term) ||
          typeStr.includes(term) ||
          moduleStr.includes(term)
        );
      });
    });
  };

  const results = searchResults();

  function openPdf(file: FileItem) {
    if (file.url.toLowerCase().includes('.pdf') || file.url.toLowerCase().includes('cloudinary')) {
      setViewingFile(file);
    } else {
      window.open(file.url, "_blank", "noopener,noreferrer");
    }
  }

  function getTypeIcon(type: string) {
    switch(type) {
      case 'notes': return <Book className="w-4 h-4 text-blue-500" />;
      case 'qbank': return <ShieldQuestion className="w-4 h-4 text-indigo-500" />;
      case 'extra': return <FileText className="w-4 h-4 text-emerald-500" />;
      default: return <FileText className="w-4 h-4 text-gray-500" />;
    }
  }

  return (
    <div className="w-full max-w-3xl mx-auto z-20 relative">
      <div className="relative flex items-center w-full h-14 rounded-2xl bg-card border border-border/50 shadow-xl shadow-primary/5 focus-within:border-primary/50 focus-within:ring-2 focus-within:ring-primary/20 transition-all overflow-hidden group">
        <div className="grid place-items-center h-full w-14 text-muted-foreground group-focus-within:text-primary transition-colors">
          {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Search className="w-5 h-5" />}
        </div>
        <input
          className="peer h-full w-full outline-none text-base bg-transparent pr-4 placeholder:text-muted-foreground text-foreground"
          type="text"
          placeholder="Search for notes... (e.g. 'WT module 2')"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      <AnimatePresence>
        {query.trim() && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 5 }}
            className="absolute top-16 left-0 right-0 max-h-[60vh] overflow-y-auto bg-card border border-border shadow-2xl rounded-2xl p-2 z-50 scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent"
          >
            {loading && results.length === 0 ? (
               <div className="p-8 text-center text-muted-foreground flex flex-col items-center gap-3">
                 <Loader2 className="w-6 h-6 animate-spin text-primary" />
                 <p>Searching resources...</p>
               </div>
            ) : results.length > 0 ? (
              <ul className="space-y-1">
                {results.map((file) => {
                  const subject = subjects.find((s) => s.subject === file.subject);
                  
                  return (
                    <li key={file.id} className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-3 hover:bg-muted/50 rounded-xl transition-colors">
                      <div className="flex items-start gap-3 flex-1 min-w-0">
                        <div className="p-2 bg-background rounded-lg border border-border/50 mt-1 sm:mt-0">
                           {getTypeIcon(file.type)}
                        </div>
                        <div className="min-w-0 flex-1">
                          <h4 className="text-sm font-medium text-foreground truncate">{file.name}</h4>
                          <p className="text-xs text-muted-foreground mt-0.5 truncate flex items-center gap-1.5">
                            <span className="font-medium text-primary/80">{subject?.name || `Subject ${file.subject}`}</span>
                            <span className="w-1 h-1 rounded-full bg-border"></span>
                            <span>Module {file.module}</span>
                            <span className="w-1 h-1 rounded-full bg-border"></span>
                            <span className="capitalize">{file.type}</span>
                          </p>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-2 pl-11 sm:pl-0 sm:shrink-0">
                         <button
                           onClick={() => openPdf(file)}
                           className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-border text-xs font-medium hover:bg-background transition-colors text-foreground"
                         >
                           <Eye className="w-3.5 h-3.5" />
                           View
                         </button>
                         <button
                           onClick={() => setDownloadingFile(file)}
                           className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-primary text-primary-foreground text-xs font-medium hover:bg-primary/90 transition-colors shadow-sm"
                         >
                           <Download className="w-3.5 h-3.5" />
                           Download
                         </button>
                      </div>
                    </li>
                  )
                })}
              </ul>
            ) : (
              <div className="p-8 text-center text-muted-foreground flex flex-col items-center gap-2">
                <Search className="w-8 h-8 text-muted-foreground/50 mb-2" />
                <p>No study materials found for "{query}"</p>
                <p className="text-xs">Try searching by subject name, module, or topic.</p>
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Download Modal */}
      {downloadingFile && (
        <DownloadModal
          isOpen={!!downloadingFile}
          onClose={() => setDownloadingFile(null)}
          file={downloadingFile}
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
    </div>
  );
}
