"use client";

import { useState } from "react";
import { X, Download, Smartphone, CheckCircle, AlertCircle } from "lucide-react";
import { saveFile } from "@/lib/db";

type FileItem = {
    id: string;
    name: string;
    url: string;
    subject?: number;
    semester?: number;
    module?: number;
    type?: string;
    mimeType?: string;
};

type Props = {
    file: FileItem;
    isOpen: boolean;
    onClose: () => void;
};

export default function DownloadModal({ file, isOpen, onClose }: Props) {
    const [downloading, setDownloading] = useState(false);
    const [progress, setProgress] = useState(0);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState<string | null>(null);

    if (!isOpen) return null;

    // Option 1: Download to Device
    const handleDeviceDownload = () => {
        // Force attachment for Cloudinary or standard download
        const downloadUrl = file.url.replace("/upload/", "/upload/fl_attachment/");
        const link = document.createElement("a");
        link.href = downloadUrl;
        link.download = file.name;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        onClose();
    };

    // Option 2: Download in App (IndexedDB)
    const handleAppDownload = async () => {
        try {
            setDownloading(true);
            setProgress(0);
            setError(null);

            const response = await fetch(file.url);
            if (!response.body) throw new Error("ReadableStream not yet supported in this browser.");

            const contentLength = response.headers.get("Content-Length");
            const total = contentLength ? parseInt(contentLength, 10) : 0;
            let loaded = 0;

            const reader = response.body.getReader();
            const chunks = [];

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;
                chunks.push(value);
                loaded += value.length;
                if (total) {
                    setProgress(Math.round((loaded / total) * 100));
                }
            }

            const blob = new Blob(chunks, { type: response.headers.get("Content-Type") || "application/pdf" });

            await saveFile({
                id: file.id,
                name: file.name,
                subject: file.subject || 0,
                semester: file.semester || 0,
                module: file.module || 0,
                type: file.type || "unknown",
                blob: blob,
                size: blob.size,
                downloadedAt: Date.now(),
                mimeType: blob.type,
                remoteUrl: file.url
            });

            setSuccess(true);
            setTimeout(() => {
                onClose();
                setSuccess(false);
                setDownloading(false);
            }, 1500);

        } catch (err: any) {
            console.error("Download failed:", err);
            // specific quota error handling could go here
            if (err.name === 'QuotaExceededError') {
                setError("Storage quota exceeded. Please delete some files.");
            } else {
                setError("Download failed. Please try again.");
            }
            setDownloading(false);
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div className="bg-card w-full max-w-md rounded-xl border border-border shadow-xl overflow-hidden">
                {/* Header */}
                <div className="flex items-center justify-between px-6 py-4 border-b border-border bg-muted/30">
                    <h3 className="font-semibold text-lg">Download Options</h3>
                    <button onClick={onClose} className="p-1 rounded-full hover:bg-muted text-muted-foreground transition">
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6 space-y-4">
                    <p className="text-sm text-muted-foreground mb-4">
                        Select how you want to download <span className="font-medium text-foreground">{file.name}</span>
                    </p>

                    {error && (
                        <div className="p-3 bg-red-500/10 text-red-500 rounded-lg text-sm flex items-center gap-2">
                            <AlertCircle className="w-4 h-4" />
                            {error}
                        </div>
                    )}

                    {success ? (
                        <div className="p-4 bg-green-500/10 text-green-600 rounded-xl flex flex-col items-center justify-center gap-2 py-8">
                            <CheckCircle className="w-10 h-10" />
                            <p className="font-medium">Saved to App successfully!</p>
                        </div>
                    ) : downloading ? (
                        <div className="space-y-3 py-4">
                            <div className="flex justify-between text-sm text-muted-foreground">
                                <span>Downloading...</span>
                                <span>{progress}%</span>
                            </div>
                            <div className="h-2 w-full bg-secondary rounded-full overflow-hidden">
                                <div
                                    className="h-full bg-primary transition-all duration-300"
                                    style={{ width: `${progress}%` }}
                                />
                            </div>
                        </div>
                    ) : (
                        <div className="grid gap-3">
                            <button
                                onClick={handleDeviceDownload}
                                className="flex items-center gap-4 p-4 rounded-xl border-2 border-border hover:border-primary/50 hover:bg-muted/50 transition-all group text-left"
                            >
                                <div className="p-3 rounded-full bg-primary/10 text-primary group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                                    <Download className="w-6 h-6" />
                                </div>
                                <div>
                                    <span className="block font-semibold">Download to Device</span>
                                    <span className="text-xs text-muted-foreground">Save to your system's download folder</span>
                                </div>
                            </button>

                            <button
                                onClick={handleAppDownload}
                                className="flex items-center gap-4 p-4 rounded-xl border-2 border-border hover:border-primary/50 hover:bg-muted/50 transition-all group text-left"
                            >
                                <div className="p-3 rounded-full bg-blue-500/10 text-blue-500 group-hover:bg-blue-500 group-hover:text-white transition-colors">
                                    <Smartphone className="w-6 h-6" />
                                </div>
                                <div>
                                    <span className="block font-semibold">Download in App</span>
                                    <span className="text-xs text-muted-foreground">Save for offline access within the app</span>
                                </div>
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
