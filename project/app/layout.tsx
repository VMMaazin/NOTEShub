import "./globals.css";
import Providers from "./providers";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "NOTEShub",
  description: "College notes storage and sharing app",
  manifest: "/manifest.json",
  themeColor: "#2563eb",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${inter.className} min-h-screen bg-background antialiased selection:bg-primary/20 selection:text-primary`}
      >
        <Providers>{children}</Providers>
        <Analytics />
      </body>
    </html>
  );
}