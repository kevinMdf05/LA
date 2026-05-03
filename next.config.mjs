/** @type {import('next').NextConfig} */
const isPages = process.env.NEXT_PUBLIC_DEPLOY_TARGET === "gh-pages";

const nextConfig = {
  reactStrictMode: true,
  // Static export for GitHub Pages. Toggled via env so local `next dev`
  // keeps using the normal server.
  ...(isPages
    ? {
        output: "export",
        basePath: "/LA",
        assetPrefix: "/LA/",
        trailingSlash: true,
        images: { unoptimized: true },
      }
    : {
        images: {
          remotePatterns: [
            { protocol: "https", hostname: "images.unsplash.com" },
            { protocol: "https", hostname: "source.unsplash.com" },
          ],
        },
      }),
};

export default nextConfig;
