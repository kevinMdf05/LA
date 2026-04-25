"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";

export default function Conclusion() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });
  const sunY = useTransform(scrollYProgress, [0, 1], ["20%", "-30%"]);
  const sunOp = useTransform(scrollYProgress, [0, 0.5, 1], [0.4, 1, 0.4]);

  return (
    <section
      ref={ref}
      id="book"
      className="relative overflow-hidden bg-gradient-to-b from-ink via-[#1A0F0A] to-[#2A1A14] py-40 md:py-56"
    >
      {/* Sun */}
      <motion.div
        className="pointer-events-none absolute left-1/2 top-1/2 -translate-x-1/2"
        style={{ y: sunY, opacity: sunOp }}
      >
        <div
          className="h-[80vmin] w-[80vmin] rounded-full"
          style={{
            background:
              "radial-gradient(circle, #FFD89B 0%, #FF8B3D 35%, #FF5A1F 60%, transparent 78%)",
            filter: "blur(2px)",
          }}
        />
      </motion.div>

      {/* horizon stripes */}
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-1/2 bg-gradient-to-t from-ink via-ink/70 to-transparent" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-2 bg-gradient-to-r from-transparent via-ember to-transparent opacity-60" />

      <div className="relative mx-auto max-w-[1200px] px-6 text-center md:px-12">
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 1 }}
          className="mb-8 font-mono text-[10px] uppercase tracking-[0.5em] text-cream/60"
        >
          End of reel
        </motion.div>

        <motion.h2
          initial={{ y: 60, opacity: 0 }}
          whileInView={{ y: 0, opacity: 1 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 1.2, ease: [0.22, 1, 0.36, 1] }}
          className="font-display text-6xl leading-[0.9] text-cream md:text-[10vw]"
        >
          You'll come back
          <br />
          <em className="gradient-text-sunset">tan, tired, in love.</em>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ delay: 0.2, duration: 1 }}
          className="mx-auto mt-10 max-w-xl text-lg text-cream/70"
        >
          Some cities you visit. Los Angeles, you survive — joyfully. By the
          last sunset, you'll have sand in your shoes, a sunburn on your
          shoulders, and a road map you'll never quite finish.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ delay: 0.4, duration: 1 }}
          className="mt-12 flex flex-col items-center justify-center gap-4 md:flex-row"
        >
          <a
            href="#top"
            data-cursor="hover"
            data-cursor-label="Replay"
            className="group inline-flex items-center gap-3 rounded-full bg-ember px-8 py-4 text-sm font-semibold uppercase tracking-[0.3em] text-ink transition hover:bg-sunset"
          >
            <span>Plan the trip</span>
            <span className="transition group-hover:translate-x-1">→</span>
          </a>
          <a
            href="#top"
            data-cursor="hover"
            className="rounded-full border border-cream/20 px-8 py-4 text-sm uppercase tracking-[0.3em] text-cream/80 backdrop-blur transition hover:border-cream/60 hover:text-cream"
          >
            Replay the intro
          </a>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.7, duration: 1 }}
          className="mt-24 flex flex-col items-center gap-6 font-mono text-[10px] uppercase tracking-[0.4em] text-cream/40"
        >
          <div className="flex items-center gap-3">
            <span className="h-[1px] w-10 bg-cream/30" />
            Vol. 01 · Filed under Sunset
            <span className="h-[1px] w-10 bg-cream/30" />
          </div>
          <div>© Designed by night, with palms in mind.</div>
        </motion.div>
      </div>
    </section>
  );
}
