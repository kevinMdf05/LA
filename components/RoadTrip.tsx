"use client";

import {
  motion,
  useMotionValueEvent,
  useScroll,
  useTransform,
} from "framer-motion";
import { useEffect, useRef, useState } from "react";
import { laPlaces, aroundLa, tripStops } from "@/lib/data";

export default function RoadTrip() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });
  const pathLen = useTransform(scrollYProgress, [0.1, 0.85], [0, 1]);
  const planeT = useTransform(scrollYProgress, [0.15, 0.85], [0, 1]);

  const all = [...laPlaces, ...aroundLa];
  const pathD = buildSmoothPath(all.map((p) => p.coords));

  return (
    <section
      ref={ref}
      id="map"
      className="relative overflow-hidden bg-ink py-32 md:py-48"
    >
      <div className="mx-auto max-w-[1600px] px-6 md:px-12">
        <div className="mb-16 flex items-end justify-between gap-8">
          <div>
            <div className="mb-4 flex items-center gap-3 font-mono text-[10px] uppercase tracking-[0.4em] text-ember">
              <span className="h-[1px] w-10 bg-ember/70" />
              The road
            </div>
            <h2 className="font-display text-5xl leading-[0.9] text-cream md:text-7xl lg:text-8xl">
              One line,
              <br />
              <em className="gradient-text-sunset">a whole coast.</em>
            </h2>
          </div>
          <div className="hidden text-right font-mono text-[10px] uppercase tracking-[0.3em] text-cream/40 md:block">
            7 days
            <br />
            12 stops
            <br />
            1,240 mi
          </div>
        </div>

        <div className="grid gap-8 md:grid-cols-12">
          {/* Map canvas */}
          <div className="relative md:col-span-8">
            <div className="relative aspect-[4/3] w-full overflow-hidden rounded-sm border border-cream/10 glass-warm">
              <div
                className="absolute inset-0 opacity-70"
                style={{
                  background:
                    "radial-gradient(ellipse at 15% 70%, rgba(255,90,31,0.18), transparent 60%), radial-gradient(ellipse at 80% 30%, rgba(242,181,68,0.15), transparent 60%), linear-gradient(135deg, #1A0F0A 0%, #2A1A14 100%)",
                }}
              />

              <svg
                className="absolute inset-0 h-full w-full opacity-40"
                viewBox="0 0 100 75"
                preserveAspectRatio="none"
              >
                {Array.from({ length: 14 }).map((_, i) => (
                  <path
                    key={i}
                    d={`M0,${5 + i * 5} Q25,${i * 5} 50,${4 + i * 5} T100,${
                      6 + i * 5
                    }`}
                    stroke="rgba(255,139,61,0.15)"
                    fill="none"
                    strokeWidth="0.15"
                  />
                ))}
              </svg>

              <svg
                className="absolute inset-0 h-full w-full"
                viewBox="0 0 100 75"
                preserveAspectRatio="none"
              >
                <path
                  d="M0,0 L0,75 L8,72 Q12,60 6,40 Q3,30 8,20 Q11,10 0,5 Z"
                  fill="rgba(20, 30, 50, 0.55)"
                />
              </svg>

              <svg
                className="absolute inset-0 h-full w-full"
                viewBox="0 0 100 75"
                preserveAspectRatio="none"
              >
                <defs>
                  <linearGradient id="rg" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0%" stopColor="#FF5A1F" />
                    <stop offset="60%" stopColor="#FF8B3D" />
                    <stop offset="100%" stopColor="#F2B544" />
                  </linearGradient>
                </defs>
                <path
                  d={pathD}
                  stroke="rgba(248,239,226,0.1)"
                  strokeWidth="0.45"
                  fill="none"
                  strokeDasharray="0.6 0.6"
                />
                <motion.path
                  d={pathD}
                  stroke="url(#rg)"
                  strokeWidth="0.55"
                  fill="none"
                  strokeLinecap="round"
                  style={{ pathLength: pathLen }}
                />
              </svg>

              {/* Stops */}
              {all.map((p) => (
                <div
                  key={p.id}
                  className="group absolute -translate-x-1/2 -translate-y-1/2"
                  style={{ left: `${p.coords.x}%`, top: `${p.coords.y}%` }}
                  data-cursor="hover"
                  data-cursor-label={p.name}
                >
                  <div className="relative">
                    <div className="absolute -inset-2 animate-ping rounded-full bg-ember/30" />
                    <div className="h-2.5 w-2.5 rounded-full bg-ember shadow-[0_0_12px_rgba(255,90,31,0.9)]" />
                    <div className="pointer-events-none absolute left-1/2 top-4 -translate-x-1/2 whitespace-nowrap rounded-full bg-ink/80 px-2 py-1 font-mono text-[9px] uppercase tracking-[0.2em] text-cream opacity-0 backdrop-blur-md transition group-hover:opacity-100">
                      {p.name}
                    </div>
                  </div>
                </div>
              ))}

              <PlaneOnPath pathD={pathD} progress={planeT} />

              <div className="absolute bottom-4 right-4 font-mono text-[10px] uppercase tracking-[0.3em] text-cream/60">
                <div className="flex items-center gap-2">
                  <div className="h-8 w-8 rounded-full border border-cream/30 p-1">
                    <div className="relative h-full w-full rounded-full border border-cream/20">
                      <div className="absolute left-1/2 top-0 h-1/2 w-[2px] -translate-x-1/2 rounded bg-ember" />
                    </div>
                  </div>
                  N
                </div>
              </div>
            </div>
          </div>

          {/* Itinerary */}
          <div className="md:col-span-4">
            <ol className="relative space-y-1">
              <div className="absolute left-3 top-2 bottom-2 w-[1px] bg-gradient-to-b from-ember via-cream/20 to-transparent" />
              {tripStops.map((s, i) => (
                <motion.li
                  key={s.name}
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, margin: "-100px" }}
                  transition={{ delay: i * 0.06, duration: 0.6 }}
                  className="relative pl-10 pr-3 py-3 hover:bg-cream/5"
                >
                  <span className="absolute left-2 top-5 h-2.5 w-2.5 rounded-full bg-ember ring-4 ring-ember/15" />
                  <div className="font-mono text-[10px] uppercase tracking-[0.3em] text-cream/50">
                    {s.time}
                  </div>
                  <div className="mt-1 font-display text-lg text-cream">
                    {s.name}
                  </div>
                  <div className="text-xs italic text-cream/60">{s.note}</div>
                </motion.li>
              ))}
            </ol>
          </div>
        </div>
      </div>
    </section>
  );
}

/**
 * Animates a small plane icon along the same SVG path used by the route line,
 * by sampling `getPointAtLength` on a hidden ref'd path and updating
 * position + rotation as the user scrolls.
 */
function PlaneOnPath({
  pathD,
  progress,
}: {
  pathD: string;
  progress: any;
}) {
  const pathRef = useRef<SVGPathElement>(null);
  const [pos, setPos] = useState<{ x: number; y: number; angle: number }>({
    x: 0,
    y: 0,
    angle: 0,
  });

  useMotionValueEvent(progress, "change", (t: number) => {
    const el = pathRef.current;
    if (!el) return;
    const total = el.getTotalLength();
    const len = Math.max(0, Math.min(1, t)) * total;
    const p = el.getPointAtLength(len);
    const ahead = el.getPointAtLength(Math.min(total, len + 0.5));
    const angle = (Math.atan2(ahead.y - p.y, ahead.x - p.x) * 180) / Math.PI;
    setPos({ x: p.x, y: p.y, angle });
  });

  // initialize once on mount
  useEffect(() => {
    const el = pathRef.current;
    if (!el) return;
    const p = el.getPointAtLength(0);
    setPos({ x: p.x, y: p.y, angle: 0 });
  }, [pathD]);

  return (
    <>
      {/* hidden path used purely for sampling */}
      <svg
        className="pointer-events-none absolute inset-0 h-full w-full opacity-0"
        viewBox="0 0 100 75"
        preserveAspectRatio="none"
        aria-hidden
      >
        <path ref={pathRef} d={pathD} fill="none" />
      </svg>

      <div
        className="pointer-events-none absolute"
        style={{
          left: `${pos.x}%`,
          top: `${(pos.y / 75) * 100}%`,
        }}
      >
        <div
          style={{ transform: `translate(-50%,-50%) rotate(${pos.angle}deg)` }}
        >
          <div
            className="h-3.5 w-3.5 rounded-full"
            style={{
              background:
                "radial-gradient(circle, #FFFFFF 0%, #FF8B3D 75%, transparent 100%)",
              boxShadow: "0 0 22px rgba(255,224,178,0.95)",
            }}
          />
        </div>
      </div>
    </>
  );
}

// Catmull-Rom-ish smooth path
function buildSmoothPath(points: { x: number; y: number }[]) {
  if (points.length === 0) return "";
  let d = `M ${points[0].x} ${points[0].y}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i - 1] ?? points[i];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[i + 2] ?? p2;
    const cp1x = p1.x + (p2.x - p0.x) / 6;
    const cp1y = p1.y + (p2.y - p0.y) / 6;
    const cp2x = p2.x - (p3.x - p1.x) / 6;
    const cp2y = p2.y - (p3.y - p1.y) / 6;
    d += ` C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${p2.x} ${p2.y}`;
  }
  return d;
}
