"use client";

import { useEffect, useState } from "react";
import { getFiles, deleteFile, getFile, checkQuota, OfflineFile } from "@/lib/db";
import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase";
import {
    Trash2,
    Eye,
    HardDrive,
    Download,
    FileText,
    ChevronDown,
    ChevronRight,
    WifiOff
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

type Subject = {
    subject: number;
    name: string;
};

// Grouped structure: Semester -> Files[]
type FilesBySemester = {
    [semester: number]: Omit<OfflineFile, "blob">[];
};

const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
        opacity: 1,
        transition: {
            staggerChildren: 0.05,
        },
    },
};

const itemVariants = {
    hidden: { opacity: 0, y: 15 },
    visible: { opacity: 1, y: 0 },
};

export default function DownloadsPage() {
    const [filesBySemester, setFilesBySemester] = useState<FilesBySemester>({});
    const [subjects, setSubjects] = useState<Record<number, Subject[]>>({});
    const [loading, setLoading] = useState(true);
    const [quota, setQuota] = useState<{ usage: number; quota: number; percentage: number } | null>(null);

    // UI State
    const [activeSemester, setActiveSemester] = useState<number>(0);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        initialize();
    }, []);

    async function initialize() {
        try {
            setLoading(true);
            const list = await getFiles();
            const quotaStats = await checkQuota();
            setQuota(quotaStats);

            if (list.length === 0) {
                setLoading(false);
                return;
            }

            // Group files by semester
            const grouped: FilesBySemester = {};
            const uniqueSemesters = new Set<number>();

            list.forEach((file) => {
                const sem = file.semester || 0;
                uniqueSemesters.add(sem);
                if (!grouped[sem]) grouped[sem] = [];
                grouped[sem].push(file);
            });

            setFilesBySemester(grouped);

            // Set initial active semester
            const sortedSemesters = Array.from(uniqueSemesters).sort((a, b) => a - b);
            if (sortedSemesters.length > 0) {
                setActiveSemester(sortedSemesters[0]);
            }

            // Fetch subjects for each semester
            const subjectMap: Record<number, Subject[]> = {};

            // Try fetching from Firestore
            try {
                for (const sem of sortedSemesters) {
                    if (sem === 0) continue; // Skip unknown semester
                    const q = query(
                        collection(db, "subjects"),
                        where("semester", "==", sem)
                    );
                    const snap = await getDocs(q);
                    const subs = snap.docs.map(doc => ({
                        subject: doc.data().subject,
                        name: doc.data().name
                    }));
                    subjectMap[sem] = subs;
                }
                setSubjects(subjectMap);
            } catch (firestoreErr) {
                console.warn("Offline or Firestore error:", firestoreErr);
                setError("Offline mode: Subject names may be unavailable.");
            }

        } catch (err) {
            console.error("Failed to initialize downloads:", err);
        } finally {
            setLoading(false);
        }
    }

    async function handleOpen(id: string) {
        try {
            const file = await getFile(id);
            const url = URL.createObjectURL(file.blob);
            window.open(url, "_blank");
            setTimeout(() => URL.revokeObjectURL(url), 60000);
        } catch (err) {
            console.error("Error opening file:", err);
            alert("Failed to open file.");
        }
    }

    async function handleDelete(id: string) {
        if (!confirm("Remove this download?")) return;
        try {
            await deleteFile(id);
            setFilesBySemester(prev => {
                const newFiles = { ...prev };
                for (const sem in newFiles) {
                    newFiles[sem] = newFiles[sem].filter(f => f.id !== id);
                    if (newFiles[sem].length === 0) {
                        delete newFiles[sem];
                    }
                }
                return newFiles;
            });
            const quotaStats = await checkQuota();
            setQuota(quotaStats);
        } catch (err) {
            console.error("Error deleting file:", err);
        }
    }

    function getSubjectName(sem: number, subId: number): string {
        const semSubjects = subjects[sem];
        if (!semSubjects) return `Subject ${subId}`;
        const found = semSubjects.find(s => s.subject === subId);
        return found ? found.name : `Subject ${subId}`;
    }

    function formatBytes(bytes: number) {
        if (bytes === 0) return "0 B";
        const k = 1024;
        const sizes = ["B", "KB", "MB", "GB"];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
    }

    // Get semesters list
    const semesters = Object.keys(filesBySemester).map(Number).sort((a, b) => a - b);
    const currentFiles = filesBySemester[activeSemester] || [];

    // Group current semester files by subject
    const currentFilesBySubject: Record<number, typeof currentFiles> = {};
    currentFiles.forEach(file => {
        const sub = file.subject || 0;
        if (!currentFilesBySubject[sub]) currentFilesBySubject[sub] = [];
        currentFilesBySubject[sub].push(file);
    });

    // Get list of subjects to display for current semester
    // Logic: Combine fetched subjects AND any subjects that have files but weren't fetched (?)
    // Primarily use fetched subjects to determine order/display, but ensure all files are shown.

    const knownSubjectIds = subjects[activeSemester]?.map(s => s.subject) || [];
    const fileSubjectIds = Object.keys(currentFilesBySubject).map(Number);

    // Merge IDs safely (ES5 compatible, avoiding Set iteration downlevel issue)
    const combinedIds = knownSubjectIds.concat(fileSubjectIds);
    const uniqueIds = combinedIds.filter((item, index) => combinedIds.indexOf(item) === index);
    const allSubjectIds = uniqueIds.sort((a, b) => a - b);

    if (loading) {
        return (
            <div className="flex justify-center items-center h-screen bg-background">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-background py-8 px-4 overflow-hidden">
            <div className="max-w-5xl mx-auto space-y-8">

                {/* Header & Stats */}
                <motion.div
                    initial={{ opacity: 0, y: -20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4 }}
                    className="flex flex-col md:flex-row md:items-center justify-between gap-6"
                >
                    <div>
                        <h1 className="text-3xl font-bold tracking-tight">Downloads</h1>
                        <p className="text-muted-foreground mt-1">
                            Your offline library
                        </p>
                        {error && (
                            <div className="flex items-center gap-2 mt-2 text-sm text-yellow-600 bg-yellow-500/10 px-3 py-1 rounded-md w-fit">
                                <WifiOff className="w-4 h-4" />
                                {error}
                            </div>
                        )}
                    </div>

                    {quota && (
                        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-4 shadow-sm min-w-[240px]">
                            <div className="p-2 bg-primary/10 rounded-full text-primary">
                                <HardDrive className="w-5 h-5" />
                            </div>
                            <div className="flex-1">
                                <div className="flex justify-between text-xs text-muted-foreground font-medium uppercase tracking-wider mb-1">
                                    <span>Storage</span>
                                    <span>{Math.round(quota.percentage)}%</span>
                                </div>
                                <div className="text-sm font-semibold">
                                    {formatBytes(quota.usage)} / {formatBytes(quota.quota)}
                                </div>
                            </div>
                        </div>
                    )}
                </motion.div>

                {/* Empty State */}
                {semesters.length === 0 ? (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="text-center py-20 border-2 border-dashed border-border rounded-xl bg-card/30"
                    >
                        <div className="inline-flex p-4 rounded-full bg-muted text-muted-foreground mb-4">
                            <Download className="w-8 h-8" />
                        </div>
                        <h3 className="text-lg font-medium">No downloads yet</h3>
                        <p className="text-muted-foreground mt-1 max-w-sm mx-auto">
                            Files you download for offline access will appear here.
                        </p>
                    </motion.div>
                ) : (
                    <div className="space-y-6">
                        {/* Semester Tabs */}
                        <motion.div
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="flex gap-2 overflow-x-auto pb-2 scrollbar-none border-b border-border"
                        >
                            {semesters.map(sem => (
                                <button
                                    key={sem}
                                    onClick={() => setActiveSemester(sem)}
                                    className={`
                                        relative px-4 py-2 text-sm font-medium transition-colors whitespace-nowrap
                                        ${activeSemester === sem
                                            ? "text-primary"
                                            : "text-muted-foreground hover:text-foreground hover:bg-muted/50 rounded-t-lg"}
                                    `}
                                >
                                    {activeSemester === sem && (
                                        <motion.div
                                            layoutId="active-semester-tab"
                                            className="absolute bottom-0 left-0 w-full h-0.5 bg-primary"
                                        />
                                    )}
                                    {sem === 0 ? "Others" : `Semester ${sem}`}
                                </button>
                            ))}
                        </motion.div>

                        {/* Subject Grid */}
                        <AnimatePresence mode="wait">
                            <motion.div
                                key={activeSemester}
                                variants={containerVariants}
                                initial="hidden"
                                animate="visible"
                                exit={{ opacity: 0, y: -10 }}
                                className="space-y-8"
                            >
                                {allSubjectIds.map(subId => {
                                    const subName = getSubjectName(activeSemester, subId);
                                    const files = currentFilesBySubject[subId] || [];

                                    return (
                                        <motion.section variants={itemVariants} key={subId} className="space-y-3">
                                            <h2 className="text-xl font-semibold flex items-center gap-2">
                                                <span className="w-1.5 h-6 bg-primary rounded-full" />
                                                {subName}
                                                <span className="text-sm font-normal text-muted-foreground ml-2">
                                                    ({files.length})
                                                </span>
                                            </h2>

                                            {files.length === 0 ? (
                                                <div className="p-8 border border-border border-dashed rounded-xl text-center text-muted-foreground text-sm bg-card/30">
                                                    No downloads for this subject
                                                </div>
                                            ) : (
                                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                                    {files.map(file => (
                                                        <motion.div
                                                            key={file.id}
                                                            whileHover={{ scale: 1.02 }}
                                                            className="group relative bg-card border border-border rounded-xl p-4 transition-all flex flex-col gap-3 shadow-sm hover:shadow-md hover:border-primary/30"
                                                        >
                                                            <div className="flex items-start justify-between gap-3">
                                                                <div className="p-2.5 rounded-lg bg-primary/10 text-primary shrink-0">
                                                                    <FileText className="w-5 h-5" />
                                                                </div>
                                                                <div className="flex flex-col items-end gap-1">
                                                                    <button
                                                                        onClick={(e) => { e.stopPropagation(); handleDelete(file.id); }}
                                                                        className="p-1.5 rounded-md text-muted-foreground hover:text-red-500 hover:bg-red-500/10 transition"
                                                                        title="Delete"
                                                                    >
                                                                        <Trash2 className="w-4 h-4" />
                                                                    </button>
                                                                </div>
                                                            </div>

                                                            <div className="flex-1 min-w-0">
                                                                <h3 className="font-medium truncate" title={file.name}>
                                                                    {file.name}
                                                                </h3>
                                                                <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
                                                                    <span>{formatBytes(file.size)}</span>
                                                                    <span>•</span>
                                                                    <span>{new Date(file.downloadedAt).toLocaleDateString()}</span>
                                                                </div>
                                                            </div>

                                                            <button
                                                                onClick={() => handleOpen(file.id)}
                                                                className="w-full mt-2 py-2 rounded-lg bg-secondary text-secondary-foreground hover:bg-primary hover:text-primary-foreground transition-colors text-sm font-medium flex items-center justify-center gap-2"
                                                            >
                                                                <Eye className="w-4 h-4" />
                                                                Open File
                                                            </button>
                                                        </motion.div>
                                                    ))}
                                                </div>
                                            )}
                                        </motion.section>
                                    );
                                })}
                            </motion.div>
                        </AnimatePresence>
                    </div>
                )}
            </div>
        </div>
    );
}
