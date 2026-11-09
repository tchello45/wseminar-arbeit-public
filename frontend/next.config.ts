import type { NextConfig } from "next"
import path from "node:path"

const nextConfig: NextConfig = {
  output: "export",
  turbopack: { root: path.resolve(import.meta.dirname, "..") },
  images: { unoptimized: true },
}

export default nextConfig
