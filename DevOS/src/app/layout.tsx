import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/layout/Sidebar";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "DevOS Dashboard",
  description: "DevOS Local Read-Only Dashboard",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning className="dark">
      <body suppressHydrationWarning className={`${inter.className} flex min-h-screen bg-background text-foreground antialiased`}>
        <Sidebar />
        <main className="flex-1 h-screen overflow-auto">
          {children}
        </main>
      </body>
    </html>
  );
}
