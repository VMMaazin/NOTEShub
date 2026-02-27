/** @type {import('next').NextConfig} */

const withPWA = require("next-pwa")({
  dest: "public",
  disable: process.env.NODE_ENV === "development",
  register: true,
  skipWaiting: true,
  fallbacks: {
    document: "/offline", // Serve the offline fallback page
  },
  cacheOnFrontEndNav: true,
  cacheStartUrl: true,
  dynamicStartUrl: false,
  reloadOnOnline: true,
});

const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    unoptimized: true,
  },
};

module.exports = withPWA(nextConfig);
