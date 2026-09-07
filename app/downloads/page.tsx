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
        <div className="min-h-screen bg-background py-8 sm:py-12 px-6 sm:px-10 lg:px-12 xl:px-16 overflow-hidden">
            <div className="max-w-[1500px] mx-auto space-y-10">

                {/* Header & Stats */}
                <motion.div
                    initial={{ opacity: 0, y: -20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4 }}
                    className="flex flex-col md:flex-row md:items-center justify-between gap-6 border-b border-border/40 pb-8"
                >
                    <div>
                        <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight">Downloads</h1>
                        <p className="text-sm sm:text-base text-muted-foreground mt-1">
                            Your offline library stored directly in local browser storage
                        </p>
                        {error && (
                            <div className="flex items-center gap-2 mt-3 text-sm text-yellow-600 bg-yellow-500/10 px-3 py-1 rounded-md w-fit border border-yellow-500/20">
                                <WifiOff className="w-4 h-4" />
                                {error}
                            </div>
                        )}
                    </div>

                    {quota && (
                        <div className="glass-card rounded-2xl p-5 flex flex-col gap-3 min-w-[280px] sm:min-w-[320px] border border-border/70 shadow-lg">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <div className="p-2.5 rounded-xl bg-primary/10 text-primary neu-flat border border-primary/20">
                                        <HardDrive className="w-5 h-5" />
                                    </div>
                                    <div>
                                        <div className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                                            Local Storage
                                        </div>
                                        <div className="text-sm font-bold text-foreground">
                                            {formatBytes(quota.usage)} <span className="text-xs font-normal text-muted-foreground">/ {formatBytes(quota.quota)}</span>
                                        </div>
                                    </div>
                                </div>
                                <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-primary/15 text-primary border border-primary/20">
                                    {Math.round(quota.percentage)}%
                                </span>
                            </div>

                            {/* Recessed Neumorphic Progress Track */}
                            <div className="w-full h-2 rounded-full bg-secondary neu-track overflow-hidden p-0.5 border border-border/40">
                                <div
                                    className="h-full rounded-full bg-gradient-to-r from-blue-500 via-indigo-500 to-cyan-400 shadow-sm transition-all duration-500"
                                    style={{ width: `${Math.min(100, Math.max(2, quota.percentage))}%` }}
                                />
                            </div>
                        </div>
                    )}
                </motion.div>

                {/* Empty State */}
                {semesters.length === 0 ? (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="text-center py-24 border-2 border-dashed border-border rounded-3xl bg-card/30 glass-card"
                    >
                        <div className="inline-flex p-4 rounded-2xl bg-muted text-muted-foreground mb-4 neu-flat">
                            <Download className="w-8 h-8" />
                        </div>
                        <h3 className="text-xl font-bold">No downloads yet</h3>
                        <p className="text-muted-foreground mt-2 max-w-sm mx-auto text-sm">
                            Documents you download for offline study will appear here and load without an internet connection.
                        </p>
                    </motion.div>
                ) : (
                    <div className="space-y-8">
                        {/* Semester Tabs (Neumorphic Switcher) */}
                        <motion.div
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="flex gap-2 overflow-x-auto pb-2 scrollbar-none neu-track bg-secondary/50 p-2 rounded-2xl border border-border/40 w-max"
                        >
                            {semesters.map(sem => (
                                <button
                                    key={sem}
                                    onClick={() => setActiveSemester(sem)}
                                    className={`
                                        relative px-5 py-2 text-sm font-semibold rounded-xl transition-all whitespace-nowrap
                                        ${activeSemester === sem
                                            ? "neu-pressed bg-background text-primary shadow-inner border border-border/50"
                                            : "text-muted-foreground hover:text-foreground hover:neu-flat hover:bg-secondary/70"}
                                    `}
                                >
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
                                className="space-y-10"
                            >
                                {allSubjectIds.map(subId => {
                                    const subName = getSubjectName(activeSemester, subId);
                                    const files = currentFilesBySubject[subId] || [];

                                    return (
                                        <motion.section variants={itemVariants} key={subId} className="space-y-4">
                                            <h2 className="text-xl font-bold flex items-center gap-2.5">
                                                <span className="w-1.5 h-6 bg-primary rounded-full" />
                                                {subName}
                                                <span className="text-xs font-semibold px-2 py-0.5 rounded-md bg-secondary text-muted-foreground border border-border/50 ml-1">
                                                    {files.length} {files.length === 1 ? "file" : "files"}
                                                </span>
                                            </h2>

                                            {files.length === 0 ? (
                                                <div className="p-8 border border-border/60 border-dashed rounded-2xl text-center text-muted-foreground text-sm bg-card/20">
                                                    No offline downloads saved for this subject yet.
                                                </div>
                                            ) : (
                                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
                                                    {files.map(file => (
                                                        <motion.div
                                                            key={file.id}
                                                            whileHover={{ y: -3 }}
                                                            className="group relative glass-card rounded-2xl p-5 transition-all flex flex-col justify-between gap-4 border border-border/70 hover:border-primary/40 hover:shadow-xl hover:shadow-primary/5"
                                                        >
                                                            <div className="flex items-start justify-between gap-3">
                                                                <div className="p-2.5 rounded-xl bg-primary/10 text-primary shrink-0 border border-primary/20">
                                                                    <FileText className="w-5 h-5" />
                                                                </div>
                                                                <button
                                                                    onClick={(e) => { e.stopPropagation(); handleDelete(file.id); }}
                                                                    className="p-1.5 rounded-lg text-muted-foreground hover:text-red-500 hover:bg-red-500/10 transition border border-transparent hover:border-red-500/20"
                                                                    title="Delete offline file"
                                                                >
                                                                    <Trash2 className="w-4 h-4" />
                                                                </button>
                                                            </div>

                                                            <div className="flex-1 min-w-0">
                                                                <h3 className="font-semibold text-foreground truncate" title={file.name}>
                                                                    {file.name}
                                                                </h3>
                                                                <div className="flex items-center gap-2 mt-1.5 text-xs text-muted-foreground">
                                                                    <span className="font-medium text-foreground/80">{formatBytes(file.size)}</span>
                                                                    <span>•</span>
                                                                    <span>{new Date(file.downloadedAt).toLocaleDateString()}</span>
                                                                </div>
                                                            </div>

                                                            <button
                                                                onClick={() => handleOpen(file.id)}
                                                                className="w-full mt-1 py-2.5 rounded-xl bg-secondary/90 text-secondary-foreground hover:bg-primary hover:text-primary-foreground transition-all duration-200 text-xs font-semibold flex items-center justify-center gap-2 border border-border/60 hover:border-primary shadow-sm"
                                                            >
                                                                <Eye className="w-4 h-4" />
                                                                Open Document
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
