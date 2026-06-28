import "./globals.css";
import type { Metadata } from "next";
import { ThemeProvider } from "../components/theme-provider";

export const metadata: Metadata = {
  title: "Fluently Web",
  description: "Fluently web experience",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
