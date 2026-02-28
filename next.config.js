/** @type {import('next').NextConfig} */

const defaultRuntimeCaching = require("next-pwa/cache");

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
  runtimeCaching: [
    ...defaultRuntimeCaching,
    {
      urlPattern: /\/downloads$/i,
      handler: "StaleWhileRevalidate",
      options: {
        cacheName: "downloads-html-cache",
        expiration: {
          maxEntries: 10,
          maxAgeSeconds: 30 * 24 * 60 * 60, // 30 Days
        },
      },
    },
    {
      urlPattern: /^https:\/\/unpkg\.com\/pdfjs-dist@.*\/build\/pdf\.worker\.min\.js$/i,
      handler: "CacheFirst",
      options: {
        cacheName: "pdfjs-worker-cache",
        expiration: {
          maxEntries: 5,
          maxAgeSeconds: 365 * 24 * 60 * 60, // 1 Year
        },
        cacheableResponse: {
          statuses: [0, 200],
        },
      },
    }
  ],
});

const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    unoptimized: true,
  },
  webpack: (config) => {
    config.resolve.alias.canvas = false;
    return config;
  },
};

module.exports = withPWA(nextConfig);
