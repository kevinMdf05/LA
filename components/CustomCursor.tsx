"use client";

import { useEffect, useState } from "react";
import { motion, useMotionValue, useSpring } from "framer-motion";

export default function CustomCursor() {
  const x = useMotionValue(-100);
  const y = useMotionValue(-100);
  const cursorX = useSpring(x, { stiffness: 500, damping: 40, mass: 0.5 });
  const cursorY = useSpring(y, { stiffness: 500, damping: 40, mass: 0.5 });
  const ringX = useSpring(x, { stiffness: 120, damping: 18, mass: 0.6 });
  const ringY = useSpring(y, { stiffness: 120, damping: 18, mass: 0.6 });

  const [variant, setVariant] = useState<"default" | "hover" | "drag">(
    "default"
  );
  const [label, setLabel] = useState<string>("");

  useEffect(() => {
    function move(e: MouseEvent) {
      x.set(e.clientX);
      y.set(e.clientY);
    }
    function over(e: MouseEvent) {
      const target = e.target as HTMLElement | null;
      if (!target) return;
      const interactive = target.closest("[data-cursor]");
      if (interactive) {
        const v = interactive.getAttribute("data-cursor") || "hover";
        const lbl = interactive.getAttribute("data-cursor-label") || "";
        setVariant(v as "hover" | "drag");
        setLabel(lbl);
      } else {
        setVariant("default");
        setLabel("");
      }
    }
    window.addEventListener("mousemove", move);
    window.addEventListener("mouseover", over);
    return () => {
      window.removeEventListener("mousemove", move);
      window.removeEventListener("mouseover", over);
    };
  }, [x, y]);

  return (
    <>
      <motion.div
        className="pointer-events-none fixed left-0 top-0 z-[100] hidden md:block"
        style={{ x: cursorX, y: cursorY, translateX: "-50%", translateY: "-50%" }}
      >
        <div className="h-1.5 w-1.5 rounded-full bg-cream mix-blend-difference" />
      </motion.div>
      <motion.div
        className="pointer-events-none fixed left-0 top-0 z-[100] hidden md:block"
        style={{ x: ringX, y: ringY, translateX: "-50%", translateY: "-50%" }}
        animate={{
          width: variant === "default" ? 36 : variant === "drag" ? 96 : 72,
          height: variant === "default" ? 36 : variant === "drag" ? 96 : 72,
          borderColor:
            variant === "default"
              ? "rgba(248,239,226,0.35)"
              : "rgba(255,139,61,0.9)",
          backgroundColor:
            variant === "default" ? "transparent" : "rgba(255,139,61,0.08)",
        }}
        transition={{ type: "spring", stiffness: 260, damping: 22 }}
      >
        <div className="flex h-full w-full items-center justify-center rounded-full border backdrop-blur-sm">
          {label && (
            <span className="font-mono text-[10px] uppercase tracking-[0.2em] text-cream">
              {label}
            </span>
          )}
        </div>
      </motion.div>
    </>
  );
}
