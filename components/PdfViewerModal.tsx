"use client";

import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { Viewer, Worker } from "@react-pdf-viewer/core";
import { defaultLayoutPlugin } from "@react-pdf-viewer/default-layout";
import { X, ExternalLink, Download } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

// Import styles
import "@react-pdf-viewer/core/lib/styles/index.css";
import "@react-pdf-viewer/default-layout/lib/styles/index.css";

interface PdfViewerModalProps {
  isOpen: boolean;
  onClose: () => void;
  fileUrl: string;
  fileName: string;
}

export default function PdfViewerModal({
  isOpen,
  onClose,
  fileUrl,
  fileName,
}: PdfViewerModalProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    document.body.style.overflow = "hidden";

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "unset";
    };
  }, [isOpen, onClose]);

  const defaultLayoutPluginInstance = defaultLayoutPlugin({
    sidebarTabs: () => [],
  });

  if (!isOpen || !mounted) return null;

  return createPortal(
    <AnimatePresence>
      <div className="fixed inset-0 z-[99999] flex flex-col bg-background">
        <motion.div
          initial={{ opacity: 0, scale: 0.98 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.98 }}
          transition={{ duration: 0.2 }}
          className="bg-card w-full h-full flex flex-col overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between px-4 sm:px-6 py-3.5 border-b border-border bg-card/95 backdrop-blur z-20 shrink-0">
            <h3 className="font-semibold text-base sm:text-lg flex-1 truncate pr-4 text-foreground">
              {fileName}
            </h3>
            <div className="flex items-center gap-1.5 sm:gap-2">
              <a
                href={fileUrl}
                download={fileName}
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 rounded-lg hover:bg-secondary text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1.5 text-xs sm:text-sm font-medium"
                title="Download PDF"
              >
                <Download className="w-4 h-4" />
                <span className="hidden sm:inline">Download</span>
              </a>
              <a
                href={fileUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 rounded-lg hover:bg-secondary text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1.5 text-xs sm:text-sm font-medium"
                title="Open in new tab"
              >
                <ExternalLink className="w-4 h-4" />
                <span className="hidden sm:inline">Open in Browser</span>
              </a>
              <div className="w-px h-5 bg-border mx-1 sm:mx-2" />
              <button
                onClick={onClose}
                className="p-2 sm:px-3 sm:py-1.5 rounded-lg bg-secondary hover:bg-destructive/15 text-foreground hover:text-destructive transition-colors flex items-center gap-1.5 text-xs sm:text-sm font-semibold border border-border/50"
                title="Close viewer (Esc)"
              >
                <X className="w-4 h-4" />
                <span className="hidden sm:inline">Close</span>
              </button>
            </div>
          </div>

          {/* PDF Viewer Content */}
          <div className="flex-1 overflow-hidden bg-zinc-100 dark:bg-zinc-900 relative">
            <Worker workerUrl={`https://unpkg.com/pdfjs-dist@3.11.174/build/pdf.worker.min.js`}>
              <div className="h-full w-full custom-pdf-viewer">
                {fileUrl ? (
                  <Viewer
                    fileUrl={fileUrl}
                    plugins={[defaultLayoutPluginInstance]}
                    theme="auto"
                    defaultScale={1}
                  />
                ) : (
                  <div className="flex items-center justify-center h-full text-muted-foreground">
                    Failed to load PDF URL.
                  </div>
                )}
              </div>
            </Worker>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>,
    document.body
  );
}
