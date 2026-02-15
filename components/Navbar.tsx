"use client";

import Link from "next/link";
import { signOut, sendPasswordResetEmail } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { Menu, X, GraduationCap } from "lucide-react"; // Import icons for mobile menu

export default function Navbar() {
  const { user, name, loading } = useAuth();
  const [isOpen, setIsOpen] = useState(false);

  async function handleResetPassword() {
    // ... (same logic)
    if (!user?.email) {
      alert("No email found for this account.");
      return;
    }

    try {
      await sendPasswordResetEmail(auth, user.email);
      alert(
        "Password reset email sent. Please check your inbox and spam folder."
      );
    } catch (err) {
      console.error(err);
      alert("Failed to send reset email. Try again later.");
    }
  }

  return (
    <nav className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        {/* Left: Brand */}
        <Link
          href="/"
          className="flex items-center gap-2.5 hover:opacity-90 transition-opacity group"
        >
          <div className="bg-gradient-to-tr from-blue-600 to-cyan-500 text-white p-2.5 rounded-xl shadow-lg shadow-blue-500/20 group-hover:scale-110 transition-transform duration-300">
            <GraduationCap className="h-5 w-5" />
          </div>
          <span className="font-bold text-xl tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-foreground to-foreground/80">
            NOTEShub
          </span>
        </Link>

        {/* Mobile Menu Button */}
        <button
          className="md:hidden p-2 rounded-md hover:bg-accent hover:text-accent-foreground"
          onClick={() => setIsOpen(!isOpen)}
        >
          {isOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>

        {/* Desktop Actions */}
        <div className="hidden md:flex items-center gap-3 text-sm font-medium">
          {/* Semester link */}
          <Link
            href="/semester/4"
            className="flex items-center px-4 py-2 rounded-full border border-border/50
                       bg-secondary/50 text-secondary-foreground
                       hover:bg-secondary hover:text-foreground
                       transition-colors"
          >
            Semester 4
          </Link>

          {!loading && user ? (
            <>
              {/* User badge */}
              <div
                className="flex items-center px-3 py-1.5 rounded-full
                           bg-muted text-muted-foreground text-xs"
              >
                <div className="w-2 h-2 rounded-full bg-green-500 mr-2"></div>
                {name || user.email}
              </div>

              {/* Reset password */}
              <button
                onClick={handleResetPassword}
                className="inline-flex px-4 py-2 rounded-md
                           text-muted-foreground hover:text-foreground
                           transition-colors"
              >
                Reset Password
              </button>

              {/* Logout */}
              <button
                onClick={() => signOut(auth)}
                className="px-4 py-2 rounded-md
                           bg-red-500/10 text-red-500
                           hover:bg-red-500/20
                           transition-colors"
              >
                Logout
              </button>
            </>
          ) : (
            <Link
              href="/admin/login"
              className="px-5 py-2 rounded-full
                         bg-primary text-primary-foreground
                         shadow-md shadow-primary/20
                         hover:bg-primary/90 hover:shadow-primary/30
                         transition-all hover:-translate-y-0.5"
            >
              Admin Login
            </Link>
          )}
        </div>
      </div>

      {/* Mobile Menu Overlay */}
      {isOpen && (
        <div className="md:hidden border-t border-border/40 bg-background">
          <div className="px-6 py-4 space-y-4 flex flex-col">
            <Link
              href="/semester/4"
              className="flex items-center gap-2 px-4 py-3 rounded-md bg-secondary/50 hover:bg-secondary transition-colors"
              onClick={() => setIsOpen(false)}
            >
              <span className="font-medium">Go to Semester 4</span>
            </Link>

            {!loading && user ? (
              <>
                <div className="flex items-center gap-2 px-2 text-sm text-muted-foreground">
                  <div className="w-2 h-2 rounded-full bg-green-500"></div>
                  Logged in as {name || user.email}
                </div>

                <button
                  onClick={() => {
                    handleResetPassword();
                    setIsOpen(false);
                  }}
                  className="text-left px-4 py-3 rounded-md hover:bg-accent transition-colors text-sm"
                >
                  Reset Password
                </button>

                <button
                  onClick={() => {
                    signOut(auth);
                    setIsOpen(false);
                  }}
                  className="text-left px-4 py-3 rounded-md bg-red-500/10 text-red-500 hover:bg-red-500/20 transition-colors text-sm font-medium"
                >
                  Logout
                </button>
              </>
            ) : (
              <Link
                href="/admin/login"
                className="text-center px-4 py-3 rounded-md bg-primary text-primary-foreground font-medium"
                onClick={() => setIsOpen(false)}
              >
                Admin Login
              </Link>
            )}
          </div>
        </div>
      )}
    </nav>
  );
}
