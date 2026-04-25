"use client";

import { motion, useMotionValueEvent, useScroll } from "framer-motion";
import { useState } from "react";
import clsx from "clsx";

const links = [
  { label: "Places", href: "#places" },
  { label: "Around", href: "#around" },
  { label: "Tables", href: "#tables" },
  { label: "Map", href: "#map" },
  { label: "Gallery", href: "#gallery" },
];

export default function Navigation() {
  const { scrollY } = useScroll();
  const [solid, setSolid] = useState(false);

  useMotionValueEvent(scrollY, "change", (y) => {
    setSolid(y > 800);
  });

  return (
    <motion.nav
      initial={{ y: -40, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ delay: 0.4, duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
      className={clsx(
        "fixed left-1/2 top-4 z-[60] -translate-x-1/2 transition-all duration-500",
        solid ? "scale-95" : "scale-100"
      )}
    >
      <div
        className={clsx(
          "flex items-center gap-2 rounded-full px-2 py-2 transition-all",
          solid ? "glass-warm" : "glass"
        )}
      >
        <a
          href="#top"
          className="flex items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold tracking-tight text-cream"
          data-cursor="hover"
          data-cursor-label="Home"
        >
          <span className="font-display text-base">L.A.</span>
          <span className="hidden font-mono text-[10px] uppercase tracking-[0.3em] text-cream/60 md:inline">
            34.05° N · 118.24° W
          </span>
        </a>
        <ul className="hidden items-center gap-1 md:flex">
          {links.map((l) => (
            <li key={l.href}>
              <a
                href={l.href}
                className="rounded-full px-4 py-2 text-xs uppercase tracking-[0.18em] text-cream/70 transition hover:bg-cream/10 hover:text-cream"
                data-cursor="hover"
              >
                {l.label}
              </a>
            </li>
          ))}
        </ul>
        <a
          href="#book"
          className="ml-1 rounded-full bg-ember px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-ink transition hover:bg-sunset"
          data-cursor="hover"
          data-cursor-label="Go"
        >
          Plan trip
        </a>
      </div>
    </motion.nav>
  );
}
