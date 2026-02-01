"use client";

type Props = {
  url: string;
  onClose: () => void;
};

export default function PdfViewer({ url, onClose }: Props) {
  return (
    <div className="fixed inset-0 z-50 bg-black/80 flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2 bg-[#161b22] border-b border-[#30363d]">
        <h2 className="text-sm font-semibold text-[#c9d1d9]">
          PDF Preview
        </h2>
        <button
          onClick={onClose}
          className="text-sm text-[#58a6ff] hover:underline"
        >
          Close
        </button>
      </div>

      {/* Viewer */}
      <iframe
        src={url}
        className="flex-1 w-full"
        loading="lazy"
      />
    </div>
  );
}
