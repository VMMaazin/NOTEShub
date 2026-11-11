"use client";

import SectionBlock from "./SectionBlock";

type Props = {
  moduleNumber: number;
  isOpen: boolean;
  onToggle: () => void;
  semester: number;
  subject: number;
};

export default function ModuleCard({
  moduleNumber,
  isOpen,
  onToggle,
  semester,
  subject,
}: Props) {
  return (
    <div className="border border-[#30363d] rounded-md bg-[#0d1117]">
      {/* Header */}
      <button
        onClick={onToggle}
        className="w-full px-4 py-3 flex items-center justify-between text-left"
      >
        <span className="text-sm font-semibold text-[#c9d1d9]">
          Module {moduleNumber}
        </span>

        <span className="text-xs text-[#8b949e]">
          {isOpen ? "Hide" : "Show"}
        </span>
      </button>

      {/* Content */}
      {isOpen && (
        <div className="px-4 pb-4 space-y-6">
          <SectionBlock
            title="📘 Notes"
            semester={semester}
            subject={subject}
            module={moduleNumber}
            type="notes"
          />

          <SectionBlock
            title="📄 Question Bank"
            semester={semester}
            subject={subject}
            module={moduleNumber}
            type="qbank"
          />

          <SectionBlock
            title="🔗 Extra Resources"
            semester={semester}
            subject={subject}
            module={moduleNumber}
            type="extra"
          />
        </div>
      )}
    </div>
  );
}
