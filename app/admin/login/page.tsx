"use client";

import { useState } from "react";
import {
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
} from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useRouter } from "next/navigation";

export default function AdminLoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [info, setInfo] = useState("");
  const router = useRouter();

  async function handleResetPassword() {
    if (!email) {
      setError("Please enter your email first.");
      return;
    }

    try {
      setError("");
      setInfo("");
      await sendPasswordResetEmail(auth, email);
      setInfo(
        "Password reset email sent. Please check your inbox and spam folder."
      );
    } catch (err) {
      setError("Failed to send reset email. Check the email address.");
    }
  }

  return (
    <div className="min-h-[70vh] flex items-center justify-center">
      <div className="w-full max-w-sm bg-[#161b22] border border-[#30363d] rounded-md">
        {/* Header */}
        <div className="px-5 py-4 border-b border-[#30363d]">
          <h1 className="text-base font-semibold">Sign in</h1>
          <p className="text-sm text-[#8b949e]">
            Admin / Author access only
          </p>
        </div>

        {/* Body */}
        <div className="px-5 py-4 space-y-4 text-sm">
          <div>
            <label className="block mb-1 text-[#8b949e]">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-[#0d1117] border border-[#30363d] rounded-md px-3 py-2 focus:outline-none focus:border-[#58a6ff]"
            />
          </div>

          <div>
            <label className="block mb-1 text-[#8b949e]">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-[#0d1117] border border-[#30363d] rounded-md px-3 py-2 focus:outline-none focus:border-[#58a6ff]"
            />

            {/* Reset password link */}
            <button
              type="button"
              onClick={handleResetPassword}
              className="mt-2 text-xs text-[#58a6ff] hover:underline"
            >
              Forgot password?
            </button>
          </div>

          {error && (
            <p className="text-xs text-red-500">{error}</p>
          )}

          {info && (
            <p className="text-xs text-green-500">{info}</p>
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-4 border-t border-[#30363d] flex justify-end">
          <button
            onClick={async () => {
              try {
                setError("");
                setInfo("");
                await signInWithEmailAndPassword(auth, email, password);
                router.push("/semester/4");
              } catch (err) {
                setError("Invalid email or password");
              }
            }}
            className="px-4 py-2 text-sm bg-[#238636] text-white rounded-md hover:bg-[#2ea043]"
          >
            Sign in
          </button>
        </div>
      </div>
    </div>
  );
}
