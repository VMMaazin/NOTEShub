"use client";

import { useEffect, useState } from "react";
import { sendPasswordResetEmail, signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext";

export default function OnboardingPage() {
  const { user, loading } = useAuth();
  const [sent, setSent] = useState(false);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    // If not logged in, send back to login
    if (!loading && !user) {
      window.location.replace("/admin/login");
    }
  }, [user, loading]);

  async function handleResetPassword() {
    if (!user?.email) {
      alert("No email found for this account.");
      return;
    }

    try {
      setSending(true);
      await sendPasswordResetEmail(auth, user.email)
      alert("Firebase reset request sent successfully");
      setSent(true);

      // Log out after sending reset email (important)
      setTimeout(async () => {
        await signOut(auth);
        window.location.replace("/admin/login");
      }, 2000);
    } catch (err) {
      console.error(err);
      alert("Failed to send reset email. Try again.");
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-md rounded-lg border border-border bg-card p-6 text-center space-y-4">
        <h1 className="text-xl font-semibold text-foreground">
          Reset Your Password
        </h1>

        <p className="text-sm text-muted-foreground">
          This is your first login. For security reasons, you must reset your
          password before continuing.
        </p>

        {!sent ? (
          <button
            onClick={handleResetPassword}
            disabled={sending}
            className="w-full mt-2 rounded-md bg-primary px-4 py-2 text-primary-foreground hover:opacity-90 transition disabled:opacity-60"
          >
            {sending ? "Sending email…" : "Send Reset Password Email"}
          </button>
        ) : (
          <p className="text-sm text-green-500">
            Reset email sent. Check your inbox and log in again.
          </p>
        )}
      </div>
    </div>
  );
}
