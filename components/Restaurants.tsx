"use client";

import { motion } from "framer-motion";
import { useState } from "react";
import { restaurants } from "@/lib/data";

export default function Restaurants() {
  const [active, setActive] = useState(0);
  const r = restaurants[active];

  return (
    <section
      id="tables"
      className="relative bg-gradient-to-b from-ink via-[#170E15] to-ink py-32 md:py-48"
    >
      <div className="mx-auto max-w-[1600px] px-6 md:px-12">
        <div className="mb-20 flex items-end justify-between gap-8">
          <div>
            <div className="mb-4 flex items-center gap-3 font-mono text-[10px] uppercase tracking-[0.4em] text-ember">
              <span className="h-[1px] w-10 bg-ember/70" />
              The tables
            </div>
            <h2 className="font-display text-5xl leading-[0.9] text-cream md:text-7xl lg:text-8xl">
              Three reservations
              <br />
              <em className="gradient-text-sunset">to remember.</em>
            </h2>
          </div>
          <div className="hidden text-right font-mono text-[10px] uppercase tracking-[0.3em] text-cream/40 md:block">
            From street food
            <br />
            to omakase
          </div>
        </div>

        <div className="grid gap-8 md:grid-cols-12">
          {/* Featured */}
          <motion.div
            key={r.id}
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
            className="relative md:col-span-8"
          >
            <div className="relative aspect-[16/10] overflow-hidden rounded-sm">
              <motion.div
                key={r.id + "-img"}
                initial={{ scale: 1.2, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 1.4, ease: [0.22, 1, 0.36, 1] }}
                className="absolute inset-0 bg-cover bg-center"
                style={{ backgroundImage: `url('${r.image}')` }}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-ink via-ink/30 to-transparent" />

              <div className="absolute bottom-8 left-8 right-8">
                <motion.div
                  key={r.id + "-meta"}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.2, duration: 0.7 }}
                >
                  <div className="font-mono text-[10px] uppercase tracking-[0.4em] text-ember">
                    {r.kind} · {r.price}
                  </div>
                  <h3 className="mt-3 font-display text-5xl leading-none text-cream md:text-7xl">
                    {r.name}
                  </h3>
                  <p className="mt-4 max-w-xl text-base text-cream/70 md:text-lg">
                    {r.description}
                  </p>
                  <div className="mt-6 flex flex-wrap gap-3 font-mono text-[10px] uppercase tracking-[0.3em]">
                    <span className="rounded-full border border-cream/20 px-3 py-1.5 text-cream/70">
                      Signature · {r.signature}
                    </span>
                    <span className="rounded-full border border-cream/20 px-3 py-1.5 text-cream/70">
                      {r.hours}
                    </span>
                  </div>
                </motion.div>
              </div>
            </div>
          </motion.div>

          {/* Selector */}
          <div className="flex flex-col gap-4 md:col-span-4">
            {restaurants.map((r2, i) => (
              <button
                key={r2.id}
                onClick={() => setActive(i)}
                data-cursor="hover"
                data-cursor-label="Select"
                className={`group relative overflow-hidden rounded-sm border text-left transition-all ${
                  i === active
                    ? "border-ember/60 glass-warm"
                    : "border-cream/10 glass hover:border-cream/30"
                }`}
              >
                <div className="flex items-center gap-4 p-4">
                  <div
                    className="h-16 w-16 shrink-0 rounded-sm bg-cover bg-center"
                    style={{ backgroundImage: `url('${r2.image}')` }}
                  />
                  <div className="flex-1">
                    <div className="font-mono text-[10px] uppercase tracking-[0.3em] text-cream/50">
                      {r2.kind}
                    </div>
                    <div className="mt-1 font-display text-xl text-cream">
                      {r2.name}
                    </div>
                  </div>
                  <div className="font-mono text-xs text-cream/40 group-hover:text-ember">
                    {r2.price}
                  </div>
                </div>
                {i === active && (
                  <motion.div
                    layoutId="rest-active"
                    className="absolute bottom-0 left-0 h-[2px] w-full bg-gradient-to-r from-ember to-gold"
                  />
                )}
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
