"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { useTheme } from "next-themes"
import { Menu, Moon, Sun, Radio, ArrowUpRight, FileText } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  Sheet,
  SheetTrigger,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from "@/components/ui/sheet"

export function NavigateButton({
  target,
  children,
  variant = "default",
  className,
}: {
  target: string
  children: React.ReactNode
  variant?: "default" | "outline" | "ghost"
  className?: string
}) {
  const router = useRouter()
  return (
    <Button
      variant={variant}
      className={className}
      onClick={() => router.push(target)}
    >
      {children}
    </Button>
  )
}

const sections = [
  { label: "Simulation", target: "/#labor" },
  { label: "Ergebnisse", target: "/#ergebnisse" },
  { label: "NanoVNA", target: "/#nanovna" },
]

export function Navigation() {
  const router = useRouter()
  const { resolvedTheme, setTheme } = useTheme()
  const [open, setOpen] = useState(false)
  return (
    <header className="site-header">
      <div className="page-width flex h-20 items-center justify-between gap-4">
        <Button
          variant="ghost"
          onClick={() => router.push("/#start")}
          aria-label="Zur Startseite"
        >
          <Radio data-icon="inline-start" />
          Funkübertragung
          <span className="hidden text-muted-foreground sm:inline">
            / LoRa-CSS
          </span>
        </Button>
        <nav
          aria-label="Hauptnavigation"
          className="hidden items-center gap-1 md:flex"
        >
          {sections.map((section) => (
            <Button
              variant="ghost"
              key={section.target}
              onClick={() => router.push(section.target)}
            >
              {section.label}
            </Button>
          ))}
        </nav>
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="icon"
            aria-label="Farbschema wechseln"
            onClick={() => {
              setTheme(resolvedTheme === "dark" ? "light" : "dark")
            }}
          >
            <Sun className="theme-sun" />
            <Moon className="theme-moon" />
          </Button>
          <Button
            variant="outline"
            className="hidden sm:inline-flex"
            onClick={() => router.push("/arbeit.pdf")}
          >
            <FileText data-icon="inline-start" />
            Arbeit als PDF
            <ArrowUpRight data-icon="inline-end" />
          </Button>
          <Sheet open={open} onOpenChange={setOpen}>
            <SheetTrigger
              render={
                <Button
                  variant="outline"
                  size="icon"
                  className="md:hidden"
                  aria-label="Menü öffnen"
                />
              }
            >
              <Menu />
            </SheetTrigger>
            <SheetContent>
              <SheetHeader>
                <SheetTitle>Funkübertragung</SheetTitle>
                <SheetDescription>
                  Die Begleitwebsite zur W-Seminararbeit.
                </SheetDescription>
              </SheetHeader>
              <nav
                aria-label="Mobile Navigation"
                className="flex flex-col gap-2 px-4"
              >
                {[
                  ...sections,
                  { label: "Arbeit als PDF", target: "/arbeit.pdf" },
                  { label: "Quellen", target: "/#quellen" },
                ].map((section) => (
                  <Button
                    variant="ghost"
                    key={section.target}
                    onClick={() => {
                      setOpen(false)
                      router.push(section.target)
                    }}
                  >
                    {section.label}
                  </Button>
                ))}
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  )
}
