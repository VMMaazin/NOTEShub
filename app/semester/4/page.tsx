"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { motion, Variants } from "framer-motion";
import { BookOpen, ArrowRight, Layers, Sparkles } from "lucide-react";

type Subject = {
  subject: number;
  name: string;
};

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
      delayChildren: 0.1,
    },
  },
};

const itemVariants: Variants = {
  hidden: { opacity: 0, scale: 0.96, y: 16 },
  visible: {
    opacity: 1,
    scale: 1,
    y: 0,
    transition: { type: "spring", stiffness: 300, damping: 24 },
  },
};

export default function Semester4Page() {
  const [subjects, setSubjects] = useState<Subject[]>([]);

  useEffect(() => {
    async function fetchSubjects() {
      try {
        const q = query(
          collection(db, "subjects"),
          where("semester", "==", 4)
        );

        const snap = await getDocs(q);
        const list: Subject[] = snap.docs.map((doc) => ({
          subject: doc.data().subject,
          name: doc.data().name,
        }));

        setSubjects(list);
      } catch (err) {
        console.error("Failed to load subjects", err);
      }
    }

    fetchSubjects();
  }, []);

  function getSubjectName(subjectNum: number) {
    const found = subjects.find(
      (s) => s.subject === subjectNum
    );
    return found ? found.name : `Subject ${subjectNum}`;
  }

  return (
    <main className="w-full max-w-[1700px] mx-auto px-4 sm:px-8 lg:px-12 xl:px-16 py-6 sm:py-10 space-y-8 sm:space-y-10 min-h-[calc(100vh-4rem)] flex flex-col justify-start">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: "easeOut" }}
        className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-border/40 pb-8"
      >
        <div className="space-y-2">
          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight text-foreground">
            Semester <span className="text-primary">4</span>
          </h1>
          <p className="text-sm sm:text-base text-muted-foreground max-w-2xl">
            Select a subject to access organized lecture notes, module question banks, and reference resources.
          </p>
        </div>

        {/* Quick info pills */}
        <div className="flex items-center gap-3 text-xs sm:text-sm font-medium text-muted-foreground self-start md:self-end">
          <div className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-secondary/70 border border-border/50">
            <Layers className="w-4 h-4 text-primary" />
            <span>8 Subjects</span>
          </div>
          <div className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-secondary/70 border border-border/50">
            <BookOpen className="w-4 h-4 text-primary" />
            <span>40 Modules Total</span>
          </div>
        </div>
      </motion.div>

      {/* Subject Cards */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 lg:gap-8"
      >
        {[1, 2, 3, 4, 5, 6, 7, 8].map((num) => (
          <Link
            key={num}
            href={`/semester/4/subject/${num}`}
            className="group block h-full focus:outline-none"
          >
            <motion.div
              variants={itemVariants}
              whileHover={{ y: -6, scale: 1.01 }}
              whileTap={{ scale: 0.98 }}
              className="
                relative flex flex-col justify-between h-full min-h-[190px] sm:min-h-[220px] rounded-2xl border border-border/70
                bg-gradient-to-b from-card/80 via-card/50 to-muted/20 backdrop-blur-sm
                p-5 sm:p-7 transition-all duration-300
                hover:border-primary/50 hover:bg-card/95
                hover:shadow-xl hover:shadow-primary/10
              "
            >
              {/* Subtle top indicator bar */}
              <div className="absolute left-6 right-6 top-0 h-0.5 rounded-full bg-gradient-to-r from-transparent via-primary to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

              {/* Card Top */}
              <div>
                <div className="flex items-center justify-between mb-4">
                  <span className="text-[11px] font-mono font-semibold tracking-wider px-2.5 py-1 rounded-md bg-secondary/80 text-secondary-foreground border border-border/60">
                    SUBJECT {String(num).padStart(2, "0")}
                  </span>
                  <div className="w-9 h-9 rounded-xl bg-primary/10 text-primary flex items-center justify-center group-hover:bg-primary group-hover:text-primary-foreground transition-all duration-300 group-hover:scale-110 shadow-sm">
                    <BookOpen className="w-4 h-4" />
                  </div>
                </div>

                <h3 className="text-xl font-bold tracking-tight text-foreground group-hover:text-primary transition-colors line-clamp-2">
                  {getSubjectName(num)}
                </h3>

                <p className="text-xs sm:text-sm text-muted-foreground mt-2">
                  Modules 1–5 • Notes & Q-Banks
                </p>
              </div>

              {/* Card Bottom */}
              <div className="pt-5 mt-4 border-t border-border/40 flex items-center justify-between">
                <div className="flex items-center gap-1">
                  {[1, 2, 3, 4, 5].map((m) => (
                    <span
                      key={m}
                      className="text-[10px] font-medium px-1.5 py-0.5 rounded bg-muted/60 text-muted-foreground group-hover:bg-muted group-hover:text-foreground transition-colors"
                    >
                      M{m}
                    </span>
                  ))}
                </div>

                <div className="text-xs font-semibold text-primary flex items-center gap-1 group-hover:translate-x-1.5 transition-transform">
                  <span>Open</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </div>
              </div>
            </motion.div>
          </Link>
        ))}
      </motion.div>
    </main>
  );
}
