"use client";

import Link from "next/link";
import { motion, Variants } from "framer-motion";

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { type: "spring", stiffness: 300, damping: 24 },
  },
};

export default function HomePage() {
  return (
    <main className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center p-6 relative overflow-hidden">
      {/* Background Decor */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1 }}
        className="absolute inset-0 -z-10 h-full w-full bg-background bg-[linear-gradient(to_right,#8080800a_1px,transparent_1px),linear-gradient(to_bottom,#8080800a_1px,transparent_1px)] bg-[size:14px_24px]"
      >
        <div className="absolute left-0 right-0 top-0 -z-10 m-auto h-[200px] w-[200px] sm:h-[310px] sm:w-[310px] rounded-full bg-primary/20 opacity-20 blur-[80px] sm:blur-[100px]"></div>
      </motion.div>

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="max-w-5xl w-full space-y-8 sm:space-y-12 py-8 sm:py-0"
      >
        {/* Header */}
        <motion.div variants={itemVariants} className="text-center space-y-4 max-w-2xl mx-auto">
          <h1 className="text-3xl sm:text-6xl font-extrabold tracking-tight lg:text-7xl">
            Your Notes, <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-violet-500">
              Simplified.
            </span>
          </h1>
          <p className="text-lg text-muted-foreground max-w-lg mx-auto leading-relaxed">
            All the best for your studies! Pick a semester below to get started with curated notes and resources.
          </p>
        </motion.div>

        {/* Semesters */}
        <motion.section variants={itemVariants}>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Active */}
            <motion.div variants={itemVariants} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
              <Link href="/semester/4" className="group block h-full">
                <SemesterCard title="Semester 4" description="Current Syllabus" active />
              </Link>
            </motion.div>

            <motion.div variants={itemVariants}>
              <SemesterCard title="Semester 1" description="Fundamentals & Basics" locked />
            </motion.div>
            <motion.div variants={itemVariants}>
              <SemesterCard title="Semester 2" description="Advanced Concepts" locked />
            </motion.div>
            <motion.div variants={itemVariants}>
              <SemesterCard title="Semester 3" description="Core Specialization" locked />
            </motion.div>
          </div>
        </motion.section>
      </motion.div>
    </main>
  );
}

function SemesterCard({
  title,
  description,
  locked,
  active,
}: {
  title: string;
  description?: string;
  locked?: boolean;
  active?: boolean;
}) {
  return (
    <div
      className={`
        relative overflow-hidden rounded-2xl border p-6 transition-colors duration-300 h-full
        flex flex-col justify-between
        ${active
          ? "bg-card border-primary/20 shadow-lg shadow-primary/5 hover:border-primary/40"
          : "bg-muted/30 border-transparent opacity-60 grayscale-[0.5] hover:opacity-100 hover:grayscale-0 cursor-not-allowed"
        }
      `}
    >
      {active && (
        <div className="absolute top-0 right-0 p-3 opacity-10 group-hover:opacity-20 transition-opacity">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="100"
            height="100"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="text-primary"
          >
            <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20" />
          </svg>
        </div>
      )}

      <div className="space-y-2 relative z-10">
        <div className="flex items-center justify-between">
          <h3 className={`font-bold text-xl ${active ? "text-foreground" : "text-muted-foreground"}`}>
            {title}
          </h3>
          {locked && (
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="text-muted-foreground"
            >
              <rect width="18" height="11" x="3" y="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
          )}
          {active && (
            <div className="h-2 w-2 rounded-full bg-green-500 animate-pulse" />
          )}
        </div>

        {description && (
          <p className="text-sm text-muted-foreground font-medium">
            {description}
          </p>
        )}
      </div>

      <div className="mt-6 pt-4 border-t border-border/50 flex items-center justify-between">
        <span className={`text-xs font-semibold uppercase tracking-wider ${active ? "text-primary" : "text-muted-foreground"}`}>
          {locked ? "Locked" : "View Notes"}
        </span>
        {active && (
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="transform transition-transform group-hover:translate-x-1"
          >
            <path d="M5 12h14" />
            <path d="m12 5 7 7-7 7" />
          </svg>
        )}
      </div>
    </div>
  );
}
