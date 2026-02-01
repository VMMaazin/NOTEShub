"use client";

import { useState } from "react";

type Props = {
  onSelect: (subjectId: number) => void;
};

const subjects = Array.from({ length: 8 }, (_, i) => ({
  id: i + 1,
  name: `Subject ${i + 1}`,
}));

export default function SubjectGrid({ onSelect }: Props) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {subjects.map((subject) => (
        <button
          key={subject.id}
          onClick={() => onSelect(subject.id)}
          className="rounded-lg border border-[#30363d] bg-[#0d1117] p-5 text-left hover:bg-[#161b22] transition"
        >
          <h3 className="text-lg font-semibold text-white">
            {subject.name}
          </h3>
          <p className="text-xs text-[#8b949e] mt-1">
            Modules 1–5
          </p>
        </button>
      ))}
    </div>
  );
}
