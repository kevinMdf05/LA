"use client";

import {
  motion,
  useMotionValueEvent,
  useScroll,
  useTransform,
  AnimatePresence,
} from "framer-motion";
import { useRef, useState } from "react";

/**
 * Cinematic intro:
 *   Phase 1 — Scroll countdown 3 → 2 → 1 → 0 (each digit blasts in: scale, blur, motion)
 *   Phase 2 — Iris opens from a closed circle into a wide aperture
 *   Phase 3 — Reveal: a Pacific runway image with a paper-plane silhouette
 *             that taxis, lifts off and flies into the horizon as the user keeps scrolling
 */
export default function IntroExperience() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start start", "end end"],
  });

  const [phase, setPhase] = useState<"count" | "iris" | "reveal" | "exit">(
    "count"
  );
  const [activeDigit, setActiveDigit] = useState<number>(3);

  useMotionValueEvent(scrollYProgress, "change", (v) => {
    // 0 — 0.55 : countdown   |   0.55 — 0.7 : iris   |   0.7 — 1 : reveal/plane
    if (v < 0.13) {
      setActiveDigit(3);
      setPhase("count");
    } else if (v < 0.28) {
      setActiveDigit(2);
      setPhase("count");
    } else if (v < 0.43) {
      setActiveDigit(1);
      setPhase("count");
    } else if (v < 0.55) {
      setActiveDigit(0);
      setPhase("count");
    } else if (v < 0.72) {
      setPhase("iris");
    } else if (v < 0.97) {
      setPhase("reveal");
    } else {
      setPhase("exit");
    }
  });

  // Iris circle radius: from 0 (closed) to 110vmax (open).
  const irisR = useTransform(scrollYProgress, [0.55, 0.72], [0, 1]);
  const irisScale = useTransform(irisR, [0, 1], [0, 1.15]);
  const irisCss = useTransform(
    irisScale,
    (v) => `${Math.min(110, v * 110)}vmax`
  );

  // Plane motion across reveal phase.
  const planeX = useTransform(scrollYProgress, [0.72, 1], ["-25%", "120%"]);
  const planeY = useTransform(scrollYProgress, [0.72, 0.85, 1], ["8%", "-15%", "-55%"]);
  const planeRot = useTransform(
    scrollYProgress,
    [0.72, 0.82, 1],
    [-2, -16, -28]
  );
  const planeScale = useTransform(scrollYProgress, [0.72, 1], [0.85, 1.45]);
  const trailOpacity = useTransform(scrollYProgress, [0.72, 0.78, 1], [0, 1, 0.2]);

  // Sky gradient parallax during reveal
  const skyShift = useTransform(scrollYProgress, [0.7, 1], ["0%", "-20%"]);

  // Subtle hint progress bar
  const progress = useTransform(scrollYProgress, [0, 1], ["0%", "100%"]);

  return (
    <section
      ref={ref}
      className="relative h-[500vh]"
      aria-label="Cinematic intro: countdown and takeoff"
    >
      {/* Sticky stage */}
      <div className="sticky top-0 h-screen w-full overflow-hidden bg-ink">
        {/* Ambient gradient backdrop (visible during countdown + iris) */}
        <div className="absolute inset-0">
          <div
            className="absolute inset-0 opacity-90"
            style={{
              background:
                "radial-gradient(ellipse at 50% 60%, rgba(255,90,31,0.22), rgba(11,11,15,0.95) 60%), radial-gradient(ellipse at 20% 20%, rgba(242,181,68,0.12), transparent 50%)",
            }}
          />
          <div className="absolute inset-0 grain" aria-hidden />
        </div>

        {/* Phase 1 — Countdown */}
        <AnimatePresence>
          {phase === "count" && (
            <motion.div
              key="count"
              className="absolute inset-0 flex items-center justify-center"
              initial={{ opacity: 1 }}
              exit={{ opacity: 0, transition: { duration: 0.4 } }}
            >
              <CountdownNumber digit={activeDigit} />

              <motion.div
                className="absolute bottom-12 left-1/2 -translate-x-1/2 flex flex-col items-center gap-3 text-cream/60"
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 }}
              >
                <span className="font-mono text-[10px] uppercase tracking-[0.4em]">
                  Scroll to begin the journey
                </span>
                <motion.div
                  className="h-8 w-[1px] bg-gradient-to-b from-cream/0 via-cream/80 to-cream/0"
                  animate={{ scaleY: [0.4, 1, 0.4] }}
                  transition={{ duration: 1.6, repeat: Infinity }}
                />
              </motion.div>

              <div className="absolute left-8 top-8 flex items-center gap-3 font-mono text-[10px] uppercase tracking-[0.3em] text-cream/50">
                <div className="h-1.5 w-1.5 animate-pulse rounded-full bg-ember" />
                Pre-flight · L.A.X.
              </div>
              <div className="absolute right-8 top-8 font-mono text-[10px] uppercase tracking-[0.3em] text-cream/50">
                T-{activeDigit.toString().padStart(2, "0")}
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Phase 2 — Iris transition (uses CSS clip-path circle) */}
        <motion.div
          className="absolute inset-0"
          style={
            {
              clipPath:
                phase === "count"
                  ? "circle(0% at 50% 50%)"
                  : "circle(var(--iris) at 50% 50%)",
              ["--iris" as string]: irisCss,
            } as React.CSSProperties
          }
        >
          <SkyScene
            skyShift={skyShift}
            planeX={planeX}
            planeY={planeY}
            planeRot={planeRot}
            planeScale={planeScale}
            trailOpacity={trailOpacity}
            phase={phase}
          />
        </motion.div>

        {/* Iris ring (the "lens edge" glow) */}
        <motion.div
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              "radial-gradient(circle at 50% 50%, transparent 38%, rgba(0,0,0,0.55) 70%, #000 100%)",
            opacity: useTransform(scrollYProgress, [0.55, 0.7, 0.85], [0.95, 0.5, 0]),
          }}
        />
        <motion.div
          className="pointer-events-none absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full border border-ember/60"
          style={{
            width: useTransform(irisScale, (v) => `${v * 80}vmax`),
            height: useTransform(irisScale, (v) => `${v * 80}vmax`),
            opacity: useTransform(
              scrollYProgress,
              [0.55, 0.66, 0.78],
              [0, 0.7, 0]
            ),
            boxShadow: "0 0 60px rgba(255,90,31,0.35) inset",
          }}
        />

        {/* Top progress bar */}
        <div className="absolute left-0 top-0 h-[2px] w-full bg-cream/5">
          <motion.div
            className="h-full origin-left bg-gradient-to-r from-ember via-sunset to-gold"
            style={{ width: progress }}
          />
        </div>

        {/* Bottom HUD when in reveal */}
        <AnimatePresence>
          {phase === "reveal" && (
            <motion.div
              key="hud"
              className="absolute bottom-8 left-8 right-8 flex items-end justify-between font-mono text-[10px] uppercase tracking-[0.3em] text-cream/70"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.6 }}
            >
              <div>
                <div className="text-cream/40">Departure</div>
                <div className="text-cream">LAX · 33.94°N</div>
              </div>
              <div className="hidden sm:block">
                <div className="text-cream/40">Heading</div>
                <div className="text-cream">270° · WNW</div>
              </div>
              <div className="text-right">
                <div className="text-cream/40">Status</div>
                <div className="text-ember">Airborne</div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </section>
  );
}

/* ---------- Countdown digit ---------- */

function CountdownNumber({ digit }: { digit: number }) {
  return (
    <div className="relative flex flex-col items-center">
      <motion.span
        className="absolute -top-12 font-mono text-[10px] uppercase tracking-[0.5em] text-ember"
        initial={{ opacity: 0, y: -8 }}
        animate={{ opacity: 1, y: 0 }}
        key={`label-${digit}`}
      >
        {digit === 0 ? "Lift-off" : "Hold for ignition"}
      </motion.span>

      <AnimatePresence mode="popLayout">
        <motion.span
          key={digit}
          initial={{
            scale: 2.4,
            opacity: 0,
            filter: "blur(40px)",
            letterSpacing: "0.4em",
          }}
          animate={{
            scale: 1,
            opacity: 1,
            filter: "blur(0px)",
            letterSpacing: "-0.04em",
          }}
          exit={{
            scale: 0.5,
            opacity: 0,
            filter: "blur(30px)",
            y: -40,
          }}
          transition={{
            duration: 0.85,
            ease: [0.22, 1, 0.36, 1],
          }}
          className="relative font-display text-[34vw] leading-none text-cream md:text-[22vw]"
          style={{
            textShadow:
              "0 0 80px rgba(255,90,31,0.35), 0 0 160px rgba(242,181,68,0.18)",
          }}
        >
          {digit}
          <span
            className="absolute inset-0 -z-10 select-none gradient-text-sunset"
            aria-hidden
            style={{ transform: "scale(1.04)" }}
          >
            {digit}
          </span>
        </motion.span>
      </AnimatePresence>

      {/* Concentric rings */}
      <div className="pointer-events-none absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full border border-ember/30"
            initial={{ width: 80, height: 80, opacity: 0 }}
            animate={{
              width: [80, 600 + i * 180],
              height: [80, 600 + i * 180],
              opacity: [0.7, 0],
            }}
            transition={{
              duration: 2.2,
              repeat: Infinity,
              delay: i * 0.55,
              ease: "easeOut",
            }}
          />
        ))}
      </div>
    </div>
  );
}

/* ---------- Sky scene with plane ---------- */

type SkySceneProps = {
  skyShift: any;
  planeX: any;
  planeY: any;
  planeRot: any;
  planeScale: any;
  trailOpacity: any;
  phase: "count" | "iris" | "reveal" | "exit";
};

function SkyScene({
  skyShift,
  planeX,
  planeY,
  planeRot,
  planeScale,
  trailOpacity,
}: SkySceneProps) {
  return (
    <div className="absolute inset-0 overflow-hidden">
      {/* Sky gradient (Pacific golden hour) */}
      <motion.div
        className="absolute inset-0"
        style={{
          y: skyShift,
          background:
            "linear-gradient(180deg, #2A1538 0%, #6B2D3B 18%, #C25A3A 38%, #FF8B3D 58%, #FFC371 75%, #FFE0B2 100%)",
        }}
      />

      {/* Sun */}
      <div className="absolute left-1/2 top-[58%] -translate-x-1/2 -translate-y-1/2">
        <div
          className="h-[36vw] w-[36vw] rounded-full"
          style={{
            background:
              "radial-gradient(circle, #FFE7B0 0%, #FFB261 40%, transparent 72%)",
            filter: "blur(2px)",
            boxShadow: "0 0 200px 60px rgba(255,178,97,0.6)",
          }}
        />
      </div>

      {/* Distant skyline silhouette */}
      <svg
        className="absolute bottom-0 left-0 w-full"
        viewBox="0 0 1600 220"
        preserveAspectRatio="none"
        style={{ height: "26vh" }}
      >
        <defs>
          <linearGradient id="city" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#1A0F0A" stopOpacity="0.6" />
            <stop offset="100%" stopColor="#1A0F0A" stopOpacity="1" />
          </linearGradient>
        </defs>
        <path
          fill="url(#city)"
          d="M0,220 L0,150 L40,150 L60,120 L90,120 L110,90 L160,90 L160,110 L210,110 L210,80 L260,80 L260,140 L320,140 L320,100 L380,100 L380,130 L440,130 L460,90 L520,90 L520,120 L600,120 L620,70 L700,70 L720,110 L780,110 L800,90 L860,90 L880,140 L940,140 L960,80 L1040,80 L1060,120 L1140,120 L1160,90 L1240,90 L1260,130 L1340,130 L1360,100 L1440,100 L1460,140 L1520,140 L1540,110 L1600,110 L1600,220 Z"
        />
      </svg>

      {/* Palm silhouettes */}
      <Palm className="absolute bottom-0 left-[6%]" delay={0.1} height={300} />
      <Palm className="absolute bottom-0 left-[16%]" delay={0.4} height={220} flip />
      <Palm className="absolute bottom-0 right-[8%]" delay={0.2} height={340} flip />
      <Palm className="absolute bottom-0 right-[22%]" delay={0.5} height={250} />

      {/* Runway lights — perspective rows */}
      <svg
        className="absolute bottom-[8%] left-1/2 -translate-x-1/2"
        width="1100"
        height="200"
        viewBox="0 0 1100 200"
      >
        <g>
          {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
            const t = i / 7;
            const y = 200 - t * 180;
            const left = 200 + t * 350;
            const right = 900 - t * 350;
            const r = 4 + (1 - t) * 4;
            return (
              <g key={i}>
                <circle cx={left} cy={y} r={r} fill="#FFE0B2" opacity={0.9 - t * 0.6} />
                <circle cx={right} cy={y} r={r} fill="#FFE0B2" opacity={0.9 - t * 0.6} />
              </g>
            );
          })}
        </g>
      </svg>

      {/* Vapor trail */}
      <motion.div
        className="absolute left-0 top-0 h-full w-full"
        style={{ opacity: trailOpacity }}
      >
        <motion.div
          className="absolute h-[3px] origin-left rounded-full bg-gradient-to-r from-transparent via-cream/70 to-cream/95"
          style={{
            width: "60%",
            x: planeX,
            y: planeY,
            rotate: planeRot,
            translateX: "-100%",
            translateY: "50%",
            filter: "blur(1px)",
            boxShadow: "0 0 24px rgba(255,255,255,0.6)",
          }}
        />
      </motion.div>

      {/* Plane */}
      <motion.div
        className="absolute left-0 top-0"
        style={{
          x: planeX,
          y: planeY,
          rotate: planeRot,
          scale: planeScale,
        }}
      >
        <PaperPlane />
      </motion.div>

      {/* Foreground vignette */}
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse at 50% 65%, transparent 50%, rgba(0,0,0,0.55) 95%)",
        }}
      />
    </div>
  );
}

/* ---------- Plane SVG ---------- */

function PaperPlane() {
  return (
    <div
      className="relative"
      style={{
        filter: "drop-shadow(0 30px 24px rgba(0,0,0,0.45))",
        width: "min(28vw, 380px)",
        height: "auto",
      }}
    >
      <svg viewBox="0 0 400 200" className="w-full">
        <defs>
          <linearGradient id="body" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#FFFFFF" />
            <stop offset="55%" stopColor="#F8EFE2" />
            <stop offset="100%" stopColor="#C9B89A" />
          </linearGradient>
          <linearGradient id="wing-shadow" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0" />
            <stop offset="100%" stopColor="#000000" stopOpacity="0.35" />
          </linearGradient>
          <linearGradient id="trim" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="#FF5A1F" />
            <stop offset="100%" stopColor="#F2B544" />
          </linearGradient>
        </defs>

        {/* Lower wing (back) */}
        <polygon
          points="40,120 200,90 360,150 200,160"
          fill="url(#body)"
          opacity="0.85"
        />
        <polygon
          points="40,120 200,90 360,150 200,160"
          fill="url(#wing-shadow)"
          opacity="0.6"
        />

        {/* Fuselage / main triangle */}
        <polygon
          points="20,60 380,100 200,140 90,110"
          fill="url(#body)"
          stroke="#E5D5B5"
          strokeWidth="1"
        />
        <polygon points="20,60 380,100 200,110" fill="#FFFFFF" opacity="0.5" />

        {/* Tail crease line */}
        <line x1="20" y1="60" x2="200" y2="140" stroke="#000" strokeOpacity="0.25" strokeWidth="1.5" />
        <line x1="380" y1="100" x2="200" y2="140" stroke="#000" strokeOpacity="0.18" strokeWidth="1.2" />

        {/* Sunset trim accent */}
        <polyline
          points="120,82 380,100"
          stroke="url(#trim)"
          strokeWidth="2"
          fill="none"
          opacity="0.75"
        />
      </svg>
    </div>
  );
}

/* ---------- Palm tree SVG ---------- */

function Palm({
  className,
  delay = 0,
  height = 240,
  flip = false,
}: {
  className?: string;
  delay?: number;
  height?: number;
  flip?: boolean;
}) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 60 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 1, delay, ease: [0.22, 1, 0.36, 1] }}
      style={{ transform: flip ? "scaleX(-1)" : undefined }}
    >
      <svg width={height * 0.6} height={height} viewBox="0 0 200 320" fill="#0A0907">
        {/* trunk */}
        <path d="M96,320 C90,260 88,180 100,80 C108,40 112,30 110,20 C108,18 102,22 100,28 C92,80 90,180 88,320 Z" />
        {/* fronds */}
        <g opacity="0.95">
          <path d="M100,30 C40,20 20,60 4,90 C30,70 60,68 100,60 Z" />
          <path d="M100,30 C160,18 180,55 198,86 C170,68 140,68 100,60 Z" />
          <path d="M100,30 C70,4 30,4 10,18 C40,22 70,40 100,52 Z" />
          <path d="M100,30 C130,4 170,4 192,18 C160,22 130,40 100,52 Z" />
          <path d="M100,32 C90,4 70,-6 50,-10 C76,18 88,32 100,46 Z" />
          <path d="M100,32 C110,4 130,-6 150,-10 C124,18 112,32 100,46 Z" />
        </g>
      </svg>
    </motion.div>
  );
}
