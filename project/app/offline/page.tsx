import { GraduationCap } from "lucide-react";
import Link from "next/link";
import { Metadata } from "next";

export const metadata: Metadata = {
    title: "Offline | NOTEShub",
};

export default function OfflinePage() {
    return (
        <div className="flex flex-col items-center justify-center min-h-[80vh] px-4 text-center">
            <div className="bg-gradient-to-tr from-blue-600 to-cyan-500 text-white p-4 rounded-2xl shadow-xl shadow-blue-500/20 mb-8">
                <GraduationCap className="h-12 w-12" />
            </div>

            <h1 className="text-3xl font-bold tracking-tight mb-4">You are offline</h1>

            <p className="text-muted-foreground mb-8 max-w-md">
                It seems you've lost your internet connection. Don't worry, any notes you have previously downloaded are still accessible offline!
            </p>

            <Link
                href="/downloads"
                className="px-6 py-3 rounded-full bg-primary text-primary-foreground font-medium shadow-md shadow-primary/20 hover:bg-primary/90 transition-all hover:-translate-y-0.5"
            >
                View Downloaded Notes
            </Link>
        </div>
    );
}
