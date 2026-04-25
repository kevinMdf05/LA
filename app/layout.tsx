import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "L.A. — A Sunset Odyssey",
  description:
    "An immersive cinematic journey through Los Angeles — palms, neon, golden hour and the open road.",
  openGraph: {
    title: "L.A. — A Sunset Odyssey",
    description:
      "An immersive cinematic journey through Los Angeles and the Californian dream.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;0,900;1,700&family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="antialiased">{children}</body>
    </html>
  );
}
