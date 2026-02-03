"use client";

import Link from "next/link";
import { signOut, sendPasswordResetEmail } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext";

export default function Navbar() {
  const { user, name, loading } = useAuth();

  async function handleResetPassword() {
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
    <nav className="w-full border-b border-border bg-background">
      <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
        {/* Left: Brand */}
        <Link
          href="/"
          className="text-lg font-semibold tracking-tight text-foreground hover:text-primary transition"
        >
          NOTEShub
        </Link>

        {/* Right: Actions */}
        <div className="flex items-center gap-3 text-sm">
          {/* Semester link */}
          <Link
            href="/semester/4"
            className="px-3 py-1.5 rounded-md border border-border
                       text-muted-foreground
                       hover:text-foreground hover:border-foreground/30
                       transition"
          >
            Semester 4
          </Link>

          {!loading && user ? (
            <>
              {/* User badge */}
              <span
                className="px-3 py-1.5 rounded-md
                           bg-muted text-muted-foreground
                           hidden sm:inline"
              >
                {name || user.email}
              </span>

              {/* Reset password */}
              <button
                onClick={handleResetPassword}
                className="px-4 py-1.5 rounded-md
                           border border-border
                           text-muted-foreground
                           hover:text-foreground hover:border-foreground/40
                           transition font-medium"
              >
                Reset Password
              </button>

              {/* Logout */}
              <button
                onClick={() => signOut(auth)}
                className="px-4 py-1.5 rounded-md
                           bg-red-500/10 text-red-400
                           hover:bg-red-500/20 hover:text-red-300
                           transition font-medium"
              >
                Logout
              </button>
            </>
          ) : (
            <Link
              href="/admin/login"
              className="px-4 py-1.5 rounded-md
                         bg-primary text-primary-foreground
                         hover:opacity-90 transition font-medium"
            >
              Admin Login
            </Link>
          )}
        </div>
      </div>
    </nav>
  );
}
