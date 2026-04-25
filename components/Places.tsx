"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import type { Place } from "@/lib/data";

export default function Places({
  id = "places",
  title,
  kicker,
  places,
}: {
  id?: string;
  title: string;
  kicker: string;
  places: Place[];
}) {
  return (
    <section id={id} className="relative py-32 md:py-48">
      <div className="mx-auto max-w-[1600px] px-6 md:px-12">
        <SectionHeading kicker={kicker} title={title} />
      </div>

      <div className="mt-24 flex flex-col gap-32 md:gap-48">
        {places.map((p, i) => (
          <PlaceCard key={p.id} place={p} index={i} />
        ))}
      </div>
    </section>
  );
}

function SectionHeading({ kicker, title }: { kicker: string; title: string }) {
  return (
    <div className="flex items-end justify-between gap-8">
      <div>
        <div className="mb-4 flex items-center gap-3 font-mono text-[10px] uppercase tracking-[0.4em] text-ember">
          <span className="h-[1px] w-10 bg-ember/70" />
          {kicker}
        </div>
        <h2 className="font-display text-5xl leading-[0.9] text-cream md:text-7xl lg:text-8xl">
          {title}
        </h2>
      </div>
      <div className="hidden text-right font-mono text-[10px] uppercase tracking-[0.3em] text-cream/40 md:block">
        Section · 02
        <br />
        Curated stops
      </div>
    </div>
  );
}

function PlaceCard({ place, index }: { place: Place; index: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });
  const imgY = useTransform(scrollYProgress, [0, 1], ["-12%", "12%"]);
  const imgScale = useTransform(scrollYProgress, [0, 0.5, 1], [1.15, 1, 1.1]);
  const textY = useTransform(scrollYProgress, [0, 1], ["8%", "-8%"]);

  const flip = index % 2 === 1;

  return (
    <article
      ref={ref}
      className="relative mx-auto w-full max-w-[1600px] px-6 md:px-12"
    >
      <div
        className={`grid items-center gap-8 md:grid-cols-12 ${
          flip ? "md:[direction:rtl]" : ""
        }`}
      >
        <div className="md:col-span-7 md:[direction:ltr]">
          <motion.div
            initial={{ opacity: 0, y: 60 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-150px" }}
            transition={{ duration: 1, ease: [0.22, 1, 0.36, 1] }}
            className="relative aspect-[5/6] overflow-hidden rounded-[2px] bg-ink"
            data-cursor="drag"
            data-cursor-label="View"
          >
            <motion.div
              className="absolute inset-0 -inset-y-[10%]"
              style={{ y: imgY, scale: imgScale }}
            >
              <div
                className="h-full w-full bg-cover bg-center"
                style={{ backgroundImage: `url('${place.image}')` }}
              />
            </motion.div>
            <div className="absolute inset-0 bg-gradient-to-t from-ink/60 via-transparent to-transparent" />

            {/* corner ticks */}
            <CornerTicks />

            <div className="absolute left-6 top-6 flex items-center gap-3 font-mono text-[10px] uppercase tracking-[0.3em] text-cream/80">
              <span className="rounded-full bg-cream/10 px-3 py-1 backdrop-blur">
                {place.kicker}
              </span>
              <span>{place.vibe}</span>
            </div>

            <div className="absolute bottom-6 left-6 right-6 flex items-end justify-between font-mono text-[10px] uppercase tracking-[0.3em] text-cream/70">
              <span>
                {place.coords.x.toFixed(2)}° · {place.coords.y.toFixed(2)}°
              </span>
              <span className="text-ember">↗ explore</span>
            </div>
          </motion.div>
        </div>

        <motion.div
          className="md:col-span-5 md:[direction:ltr]"
          style={{ y: textY }}
        >
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-150px" }}
            transition={{ duration: 1, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="font-mono text-[10px] uppercase tracking-[0.4em] text-ember">
              N°{place.kicker}
            </div>
            <h3 className="mt-4 font-display text-4xl leading-[0.95] text-cream md:text-6xl">
              {place.name}
            </h3>
            <p className="mt-4 text-lg italic text-cream/70 md:text-xl">
              {place.tagline}
            </p>
            <p className="mt-6 max-w-md text-base leading-relaxed text-cream/70">
              {place.description}
            </p>
            <div className="mt-8 flex items-center gap-4 font-mono text-[10px] uppercase tracking-[0.3em] text-cream/50">
              <span className="h-[1px] w-10 bg-cream/30" />
              <span>{place.vibe}</span>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </article>
  );
}

function CornerTicks() {
  return (
    <>
      {[
        "left-3 top-3",
        "right-3 top-3 rotate-90",
        "left-3 bottom-3 -rotate-90",
        "right-3 bottom-3 rotate-180",
      ].map((c) => (
        <span
          key={c}
          className={`absolute h-4 w-4 ${c}`}
          aria-hidden
          style={{
            background:
              "linear-gradient(to right, rgba(248,239,226,0.7) 60%, transparent 60%) top/100% 1px no-repeat, linear-gradient(to bottom, rgba(248,239,226,0.7) 60%, transparent 60%) left/1px 100% no-repeat",
          }}
        />
      ))}
    </>
  );
}
