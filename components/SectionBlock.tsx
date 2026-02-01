"use client";

import FileList from "./FileList";
import UploadFile from "./UploadFile";

type Props = {
  title: string;
  semester: number;
  subject: number;
  module: number;
  type: "notes" | "qbank" | "extra";
};

export default function SectionBlock({
  title,
  semester,
  subject,
  module,
  type,
}: Props) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <h4 className="text-sm font-semibold text-[#c9d1d9]">
          {title}
        </h4>

        <UploadFile
          semester={semester}
          subject={subject}
          module={module}
          type={type}
        />
      </div>

      <FileList
        semester={semester}
        subject={subject}
        module={module}
        type={type}
      />
    </div>
  );
}
