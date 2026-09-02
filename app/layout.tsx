import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GoldDesk — XAUUSD Chart & Chat",
  description: "A focused XAUUSD workspace for chart review and ChatGPT access on Mac and iPhone.",
  applicationName: "GoldDesk",
  manifest: "/manifest.webmanifest",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/apple-touch-icon.svg",
  },
  openGraph: {
    title: "GoldDesk — Chart & Chat",
    description: "Your focused XAUUSD workspace, ready on Mac and iPhone.",
    images: ["/og.png"],
  },
};

export const viewport: Viewport = {
  themeColor: "#0b0b0a",
  colorScheme: "dark",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
