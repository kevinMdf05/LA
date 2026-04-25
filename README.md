# L.A. — A Sunset Odyssey

A cinematic single-page journey through Los Angeles and the Californian dream.
Built as a premium showcase: a scroll-driven intro (countdown → iris → plane
takeoff), then storytelling sections through L.A. landmarks, restaurants,
detours, a road-trip map, gallery and an emotional outro.

## Stack

- **Next.js 14** (App Router, RSC)
- **TypeScript**
- **Tailwind CSS** for styling + custom palette (sunset, ember, cream, ink…)
- **Framer Motion** for scroll animations / micro-interactions
- **Lenis** for inertia / smooth scroll

## Highlights

- **Scroll-locked intro** (`components/IntroExperience.tsx`) — 3 → 2 → 1 → 0
  countdown with blur/scale entry, then a clip-path **iris** that opens onto
  a Pacific golden-hour scene and a paper plane that taxis, lifts off and
  flies into the horizon as the user keeps scrolling.
- **Custom cursor** with contextual hover labels.
- **Parallax storytelling cards** for every L.A. landmark (Beverly Hills,
  Hollywood Sign, Griffith Observatory, Santa Monica, Venice, Rodeo Drive,
  Runyon Canyon, El Matador) and detours (Joshua Tree, Route 66, Palm
  Springs, Big Sur).
- **Restaurant selector** for In-N-Out, Catch LA, Nobu Malibu.
- **Road-trip SVG map** with an animated path that draws as you scroll.
- **Marquee strip**, glassmorphism, grain overlay, sunset gradient text.

## Run locally

```bash
npm install
npm run dev
```

Open http://localhost:3000.

## Structure

```
app/
  layout.tsx          # fonts, metadata, global styles
  page.tsx            # composes the experience
  globals.css         # Tailwind + utilities (glass, grain, gradients)
components/
  IntroExperience.tsx # 🎬 the 3-2-1 + iris + plane sequence
  SmoothScroll.tsx    # Lenis wrapper
  CustomCursor.tsx    # spring-driven cursor with hover variants
  Navigation.tsx      # floating glass pill nav
  Hero.tsx            # parallax landing
  Places.tsx          # storytelling cards (used twice)
  Restaurants.tsx     # tabbed featured / selector
  RoadTrip.tsx        # SVG map + animated path + itinerary
  Gallery.tsx         # masonry-ish photo grid with parallax
  Conclusion.tsx      # emotional outro / CTA
lib/
  data.ts             # places, restaurants, trip stops
```
