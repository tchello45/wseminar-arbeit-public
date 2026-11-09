import type { Metadata } from "next"
import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"

export const metadata: Metadata = {
  icons: { icon: "/icon.svg" },
  title: "LoRa-CSS – Simulation und Messung",
  description:
    "Begleitwebsite zur W-Seminararbeit über LoRa-CSS: interaktive Symbolsimulation, numerische Ergebnisse und NanoVNA-Messungen zur komplexen Reflexion.",
}

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="de" suppressHydrationWarning>
      <body>
        <ThemeProvider defaultTheme="dark" enableSystem={false}>
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
