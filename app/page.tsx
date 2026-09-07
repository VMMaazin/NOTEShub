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
        className="max-w-7xl w-full space-y-8 sm:space-y-12 py-8 sm:py-0"
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
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-6 relative z-10">
            {/* Semester 5 - Featured / Pop Out */}
            <motion.div variants={itemVariants} whileHover={{ y: -4, scale: 1.02 }} whileTap={{ scale: 0.98 }}>
              <Link href="/semester/5" className="group block h-full focus:outline-none">
                <SemesterCard
                  title="Semester 5"
                  description="Current Syllabus"
                  variant="featured"
                  statusText="Current"
                />
              </Link>
            </motion.div>

            {/* Semester 4 - Subtle / Available */}
            <motion.div variants={itemVariants} whileHover={{ y: -2, scale: 1.01 }} whileTap={{ scale: 0.98 }}>
              <Link href="/semester/4" className="group block h-full focus:outline-none">
                <SemesterCard
                  title="Semester 4"
                  description="Previous Syllabus"
                  variant="available"
                  statusText="Available"
                />
              </Link>
            </motion.div>

            {/* Locked Semesters */}
            <motion.div variants={itemVariants}>
              <SemesterCard title="Semester 1" description="Fundamentals & Basics" variant="locked" />
            </motion.div>
            <motion.div variants={itemVariants}>
              <SemesterCard title="Semester 2" description="Advanced Concepts" variant="locked" />
            </motion.div>
            <motion.div variants={itemVariants}>
              <SemesterCard title="Semester 3" description="Core Specialization" variant="locked" />
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
  variant,
  statusText,
  active,
  locked,
}: {
  title: string;
  description?: string;
  variant?: "featured" | "available" | "locked";
  statusText?: string;
  active?: boolean;
  locked?: boolean;
}) {
  const mode = variant || (locked ? "locked" : active ? "featured" : "locked");

  if (mode === "featured") {
    return (
      <div className="relative overflow-hidden rounded-2xl border-2 border-primary/50 bg-gradient-to-b from-card via-card to-primary/5 p-6 transition-all duration-300 h-full flex flex-col justify-between shadow-xl shadow-primary/10 hover:shadow-2xl hover:shadow-primary/20 hover:border-primary group">
        {/* Glowing top line */}
        <div className="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-blue-500 via-indigo-500 to-cyan-400" />

        {/* Background watermark */}
        <div className="absolute top-0 right-0 p-3 opacity-15 group-hover:opacity-25 transition-opacity pointer-events-none">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="90"
            height="90"
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

        <div className="space-y-2 relative z-10">
          <div className="flex items-center justify-between">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wider bg-primary/15 text-primary border border-primary/30">
              <span className="h-1.5 w-1.5 rounded-full bg-green-500 animate-pulse" />
              {statusText || "Current"}
            </span>
          </div>

          <h3 className="font-extrabold text-2xl text-foreground tracking-tight pt-1 group-hover:text-primary transition-colors">
            {title}
          </h3>

          {description && (
            <p className="text-sm text-muted-foreground font-medium">
              {description}
            </p>
          )}
        </div>

        <div className="mt-6 pt-4 border-t border-border/60 flex items-center justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-primary">
            View Notes
          </span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="text-primary transform transition-transform group-hover:translate-x-1"
          >
            <path d="M5 12h14" />
            <path d="m12 5 7 7-7 7" />
          </svg>
        </div>
      </div>
    );
  }

  if (mode === "available") {
    return (
      <div className="relative overflow-hidden rounded-2xl border border-border/60 bg-card/40 p-6 transition-all duration-300 h-full flex flex-col justify-between hover:border-border hover:bg-card/70 group">
        <div className="space-y-2 relative z-10">
          <div className="flex items-center justify-between">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium text-muted-foreground bg-secondary/70 border border-border/50">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500/70" />
              {statusText || "Available"}
            </span>
          </div>

          <h3 className="font-semibold text-lg text-foreground/80 pt-1 group-hover:text-foreground transition-colors">
            {title}
          </h3>

          {description && (
            <p className="text-xs text-muted-foreground font-normal">
              {description}
            </p>
          )}
        </div>

        <div className="mt-6 pt-4 border-t border-border/40 flex items-center justify-between">
          <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground group-hover:text-foreground transition-colors">
            View Notes
          </span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="15"
            height="15"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="text-muted-foreground group-hover:text-foreground transform transition-transform group-hover:translate-x-1"
          >
            <path d="M5 12h14" />
            <path d="m12 5 7 7-7 7" />
          </svg>
        </div>
      </div>
    );
  }

  // mode === "locked"
  return (
    <div className="relative overflow-hidden rounded-2xl border border-border/30 bg-muted/20 p-6 transition-colors duration-300 h-full flex flex-col justify-between opacity-50 cursor-not-allowed">
      <div className="space-y-2 relative z-10">
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-medium text-muted-foreground/80 uppercase tracking-wider">
            Archived
          </span>
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
            className="text-muted-foreground/70"
          >
            <rect width="18" height="11" x="3" y="11" rx="2" ry="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
        </div>

        <h3 className="font-semibold text-lg text-muted-foreground pt-1">
          {title}
        </h3>

        {description && (
          <p className="text-xs text-muted-foreground/70">
            {description}
          </p>
        )}
      </div>

      <div className="mt-6 pt-4 border-t border-border/30 flex items-center justify-between">
        <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground/60">
          Locked
        </span>
      </div>
    </div>
  );
}
