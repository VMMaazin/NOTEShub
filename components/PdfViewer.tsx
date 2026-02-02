"use client";

import { useEffect } from "react";

type Props = {
  url: string;
  onClose: () => void;
};

export default function PdfViewer({ url, onClose }: Props) {
  useEffect(() => {
    // Open PDF in native browser viewer
    window.open(url, "_blank", "noopener,noreferrer");

    // Immediately close the viewer state
    onClose();
  }, [url, onClose]);

  // Nothing is rendered on screen
  return null;
}
