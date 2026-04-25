"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";

export default function Hero() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start start", "end start"],
  });
  const titleY = useTransform(scrollYProgress, [0, 1], ["0%", "-30%"]);
  const subY = useTransform(scrollYProgress, [0, 1], ["0%", "-60%"]);
  const bgY = useTransform(scrollYProgress, [0, 1], ["0%", "20%"]);
  const opacity = useTransform(scrollYProgress, [0, 0.8], [1, 0]);

  return (
    <section
      ref={ref}
      id="top"
      className="relative h-[110vh] w-full overflow-hidden"
    >
      {/* parallax photo backdrop */}
      <motion.div
        className="absolute inset-0 -z-10"
        style={{ y: bgY }}
      >
        <div
          className="absolute inset-0 bg-cover bg-center"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1542223616-740d5dff7f56?auto=format&fit=crop&w=2400&q=85')",
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-b from-ink/30 via-ink/10 to-ink" />
        <div
          className="absolute inset-0"
          style={{
            background:
              "radial-gradient(ellipse at 50% 80%, rgba(255,90,31,0.18), transparent 60%)",
          }}
        />
      </motion.div>

      <div className="relative z-10 mx-auto flex h-full max-w-[1600px] flex-col justify-end px-6 pb-24 md:px-12">
        {/* small kicker */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3, duration: 0.8 }}
          className="mb-8 flex items-center gap-4 font-mono text-[10px] uppercase tracking-[0.4em] text-cream/70"
        >
          <span className="h-[1px] w-12 bg-cream/60" />
          A Sunset Odyssey · Vol. 01
          <span className="h-[1px] w-12 bg-cream/60" />
        </motion.div>

        <motion.h1
          style={{ y: titleY, opacity }}
          className="font-display text-[18vw] leading-[0.85] text-cream md:text-[12vw]"
        >
          <SplitWord text="Los" delay={0.2} />
          <br />
          <span className="gradient-text-sunset italic">
            <SplitWord text="Angeles" delay={0.5} />
          </span>
        </motion.h1>

        <motion.div
          style={{ y: subY, opacity }}
          className="mt-10 grid gap-10 md:grid-cols-3"
        >
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.2, duration: 0.8 }}
            className="text-balance text-base text-cream/80 md:col-span-2 md:max-w-2xl md:text-xl"
          >
            Seven days under endless palms. Boardwalks at sunrise, observatories
            at dusk, sea stacks at golden hour. A road trip stitched into the
            ribcage of California.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.4, duration: 0.8 }}
            className="flex flex-col gap-3 self-end font-mono text-[11px] uppercase tracking-[0.25em] text-cream/70"
          >
            <div className="flex justify-between">
              <span>Distance</span>
              <span className="text-cream">1,240 mi</span>
            </div>
            <div className="flex justify-between">
              <span>Stops</span>
              <span className="text-cream">12</span>
            </div>
            <div className="flex justify-between">
              <span>Soundtrack</span>
              <span className="text-cream">Vol. 1 · 2h41</span>
            </div>
          </motion.div>
        </motion.div>
      </div>

      {/* marquee strip */}
      <div className="absolute bottom-0 left-0 right-0 overflow-hidden border-y border-cream/10 bg-ink/40 backdrop-blur-md">
        <div className="flex w-max animate-marquee gap-12 py-4 font-mono text-[11px] uppercase tracking-[0.4em] text-cream/70">
          {Array.from({ length: 2 }).map((_, j) => (
            <div key={j} className="flex gap-12">
              {[
                "Pacific Coast Hwy",
                "Golden Hour 19:42",
                "Tacos · 24/7",
                "Sunset Boulevard",
                "Palm Trees, Always",
                "Mulholland Drive",
                "73°F · Light Wind",
                "Vinyl Crackle",
              ].map((t) => (
                <span key={t} className="flex items-center gap-12">
                  {t}
                  <span className="text-ember">✦</span>
                </span>
              ))}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function SplitWord({ text, delay = 0 }: { text: string; delay?: number }) {
  return (
    <span className="inline-block overflow-hidden align-bottom">
      <motion.span
        className="inline-block"
        initial={{ y: "100%" }}
        animate={{ y: 0 }}
        transition={{ duration: 1, ease: [0.22, 1, 0.36, 1], delay }}
      >
        {text}
      </motion.span>
    </span>
  );
}
