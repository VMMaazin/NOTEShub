"use client";

import { useState } from "react";
import { Viewer, Worker } from "@react-pdf-viewer/core";
import { defaultLayoutPlugin } from "@react-pdf-viewer/default-layout";
import { X, ExternalLink } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { TransformWrapper, TransformComponent } from "react-zoom-pan-pinch";

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
    const defaultLayoutPluginInstance = defaultLayoutPlugin();

    if (!isOpen) return null;

    return (
        <AnimatePresence>
            <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 md:p-8"
            >
                <motion.div
                    initial={{ opacity: 0, scale: 0.95, y: 20 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95, y: 20 }}
                    transition={{ type: "spring", damping: 25, stiffness: 300 }}
                    className="bg-card w-full h-[90vh] max-w-6xl rounded-2xl border border-border shadow-2xl flex flex-col overflow-hidden"
                >
                    {/* Header */}
                    <div className="flex items-center justify-between px-6 py-4 border-b border-border bg-muted/30">
                        <h3 className="font-semibold text-lg flex-1 truncate pr-4">
                            {fileName}
                        </h3>
                        <div className="flex items-center gap-2">
                            <a
                                href={fileUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="p-2 rounded-full hover:bg-muted text-muted-foreground transition-colors flex items-center gap-2 text-sm font-medium"
                                title="Open in new tab"
                            >
                                <ExternalLink className="w-4 h-4" />
                                <span className="hidden sm:inline">Open in Browser</span>
                            </a>
                            <div className="w-px h-6 bg-border mx-2" />
                            <button
                                onClick={onClose}
                                className="p-2 rounded-full hover:bg-destructive/10 hover:text-destructive transition-colors text-muted-foreground"
                                title="Close viewer"
                            >
                                <X className="w-5 h-5" />
                            </button>
                        </div>
                    </div>

                    {/* PDF Viewer Content */}
                    <div className="flex-1 overflow-hidden bg-[#e4e4e4] dark:bg-neutral-900 relative">
                        <Worker workerUrl={`https://unpkg.com/pdfjs-dist@3.11.174/build/pdf.worker.min.js`}>
                            <TransformWrapper
                                initialScale={1}
                                minScale={1}
                                maxScale={5}
                                centerOnInit
                                wheel={{ step: 0.1 }}
                            >
                                <TransformComponent
                                    wrapperStyle={{ width: "100%", height: "100%" }}
                                    contentStyle={{ width: "100%", height: "100%" }}
                                >
                                    <div className="h-full w-full custom-pdf-viewer">
                                        {fileUrl ? (
                                            <Viewer
                                                fileUrl={fileUrl}
                                                plugins={[defaultLayoutPluginInstance]}
                                                theme="auto"
                                            />
                                        ) : (
                                            <div className="flex items-center justify-center h-full text-muted-foreground">
                                                Failed to load PDF URL.
                                            </div>
                                        )}
                                    </div>
                                </TransformComponent>
                            </TransformWrapper>
                        </Worker>
                    </div>
                </motion.div>
            </motion.div>
        </AnimatePresence>
    );
}
