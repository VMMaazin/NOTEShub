"use client";

import Link from "next/link";
import { motion, Variants } from "framer-motion";
import HomeSearch from "@/components/HomeSearch";

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
      {/* Dynamic Animated Background */}
      <div className="absolute inset-0 -z-10 h-full w-full bg-background overflow-hidden pointer-events-none">
        {/* Subtle Grid */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)]" />

        {/* Floating Orbs */}
        <motion.div
          animate={{
            x: [0, 100, 0],
            y: [0, 50, 0],
            scale: [1, 1.2, 1],
          }}
          transition={{ duration: 15, repeat: Infinity, ease: "easeInOut" }}
          className="absolute top-[-10%] left-[-10%] w-[40vw] h-[40vw] max-w-[600px] max-h-[600px] rounded-full bg-primary/40 dark:bg-primary/30 blur-[80px] sm:blur-[120px] mix-blend-multiply dark:mix-blend-screen opacity-50 dark:opacity-60"
        />
        <motion.div
          animate={{
            x: [0, -80, 0],
            y: [0, -100, 0],
            scale: [1, 1.5, 1],
          }}
          transition={{ duration: 20, repeat: Infinity, ease: "easeInOut", delay: 2 }}
          className="absolute top-[20%] right-[-10%] w-[35vw] h-[35vw] max-w-[500px] max-h-[500px] rounded-full bg-violet-400/50 dark:bg-violet-600/30 blur-[80px] sm:blur-[120px] mix-blend-multiply dark:mix-blend-screen opacity-40 dark:opacity-50"
        />
        <motion.div
          animate={{
            x: [0, 50, 0],
            y: [0, 100, 0],
            scale: [1, 1.1, 1],
          }}
          transition={{ duration: 18, repeat: Infinity, ease: "easeInOut", delay: 1 }}
          className="absolute bottom-[-20%] left-[20%] w-[45vw] h-[45vw] max-w-[700px] max-h-[700px] rounded-full bg-cyan-400/50 dark:bg-cyan-500/30 blur-[80px] sm:blur-[120px] mix-blend-multiply dark:mix-blend-screen opacity-40 dark:opacity-50"
        />
      </div>

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

        {/* Search */}
        <motion.div variants={itemVariants} className="w-full relative z-30">
          <HomeSearch />
        </motion.div>

        {/* Semesters */}
        <motion.section variants={itemVariants} className="pt-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 relative z-10">
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
