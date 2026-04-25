"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";

const shots = [
  {
    src: "https://images.unsplash.com/photo-1502920917128-1aa500764cbd?auto=format&fit=crop&w=1400&q=80",
    title: "Pacific Coast Hwy",
    span: "row-span-2",
  },
  {
    src: "https://images.unsplash.com/photo-1493558103817-58b2924bce98?auto=format&fit=crop&w=1400&q=80",
    title: "Neon Sunset",
    span: "",
  },
  {
    src: "https://images.unsplash.com/photo-1444723121867-7a241cacace9?auto=format&fit=crop&w=1400&q=80",
    title: "Palm Sky",
    span: "",
  },
  {
    src: "https://images.unsplash.com/photo-1602002418082-a4443e081dd1?auto=format&fit=crop&w=1400&q=80",
    title: "Boardwalk",
    span: "row-span-2",
  },
  {
    src: "https://images.unsplash.com/photo-1602002418816-5c0aeef426aa?auto=format&fit=crop&w=1400&q=80",
    title: "Diner Glow",
    span: "",
  },
  {
    src: "https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?auto=format&fit=crop&w=1400&q=80",
    title: "Topanga",
    span: "",
  },
  {
    src: "https://images.unsplash.com/photo-1518391846015-55a9cc003b25?auto=format&fit=crop&w=1400&q=80",
    title: "Hwy 1",
    span: "col-span-2",
  },
  {
    src: "https://images.unsplash.com/photo-1499083097717-a156f85f0516?auto=format&fit=crop&w=1400&q=80",
    title: "Mojave Dusk",
    span: "",
  },
];

export default function Gallery() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });
  const xL = useTransform(scrollYProgress, [0, 1], ["-8%", "8%"]);
  const xR = useTransform(scrollYProgress, [0, 1], ["8%", "-8%"]);

  return (
    <section ref={ref} id="gallery" className="relative py-32 md:py-48">
      <div className="mx-auto max-w-[1600px] px-6 md:px-12">
        <div className="mb-16 flex items-end justify-between gap-8">
          <div>
            <div className="mb-4 flex items-center gap-3 font-mono text-[10px] uppercase tracking-[0.4em] text-ember">
              <span className="h-[1px] w-10 bg-ember/70" />
              The film roll
            </div>
            <h2 className="font-display text-5xl leading-[0.9] text-cream md:text-7xl lg:text-8xl">
              Frames from
              <br />
              <em className="gradient-text-sunset">a sunlit week.</em>
            </h2>
          </div>
        </div>

        <div className="grid auto-rows-[18vw] grid-cols-2 gap-3 md:grid-cols-4 md:gap-4">
          {shots.map((s, i) => (
            <motion.figure
              key={s.src}
              className={`group relative overflow-hidden rounded-sm bg-ink ${s.span}`}
              style={i % 2 === 0 ? { x: xL } : { x: xR }}
              data-cursor="hover"
              data-cursor-label={s.title}
            >
              <motion.div
                initial={{ scale: 1.2, opacity: 0 }}
                whileInView={{ scale: 1, opacity: 1 }}
                viewport={{ once: true, margin: "-100px" }}
                transition={{ duration: 1.4, ease: [0.22, 1, 0.36, 1] }}
                className="absolute inset-0 bg-cover bg-center transition-transform duration-[1200ms] ease-[cubic-bezier(0.22,1,0.36,1)] group-hover:scale-110"
                style={{ backgroundImage: `url('${s.src}')` }}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-ink/70 via-transparent to-transparent opacity-0 transition group-hover:opacity-100" />
              <figcaption className="absolute bottom-3 left-3 font-mono text-[10px] uppercase tracking-[0.3em] text-cream opacity-0 transition group-hover:opacity-100">
                {s.title}
              </figcaption>
            </motion.figure>
          ))}
        </div>
      </div>
    </section>
  );
}
