"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { collection, getDocs, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase";

type Subject = {
  subject: number;
  name: string;
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
    <main className="max-w-7xl mx-auto px-6 py-10 space-y-10">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground">
          Semester <span className="text-primary">4</span>
        </h1>
        <p className="text-sm text-muted-foreground mt-2">
          Select a subject to view notes, question banks, and resources
        </p>
      </div>

      {/* Subject Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {[1, 2, 3, 4, 5, 6, 7, 8].map((num) => (
          <Link
            key={num}
            href={`/semester/4/subject/${num}`}
            className="group"
          >
            <div
              className="
                relative h-full rounded-xl border border-border
                bg-gradient-to-br from-background to-muted/30
                p-6 transition-all duration-300
                hover:-translate-y-1
                hover:border-primary/50
                hover:shadow-lg hover:shadow-primary/10
              "
            >
              {/* Accent bar */}
              <div className="absolute left-0 top-0 h-full w-1 rounded-l-xl bg-primary opacity-0 group-hover:opacity-100 transition" />

              <h3 className="text-lg font-semibold text-foreground group-hover:text-primary transition">
                {getSubjectName(num)}
              </h3>

              <p className="text-xs text-muted-foreground mt-2">
                Modules 1–5
              </p>

              <div className="mt-4 text-xs font-medium text-primary opacity-0 group-hover:opacity-100 transition">
                Open →
              </div>
            </div>
          </Link>
        ))}
      </div>
    </main>
  );
}
