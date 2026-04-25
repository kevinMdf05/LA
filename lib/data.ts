export type Place = {
  id: string;
  name: string;
  kicker: string;
  tagline: string;
  description: string;
  image: string;
  coords: { x: number; y: number };
  vibe: string;
};

export const laPlaces: Place[] = [
  {
    id: "proud-bird",
    name: "The Proud Bird",
    kicker: "01",
    tagline: "Where engines purr and palms applaud",
    description:
      "On the edge of LAX, a runway-side institution where vintage warbirds rest beneath the takeoff path. Watch a 747 thunder overhead, a martini in hand, the smell of jet fuel mixing with sea salt.",
    image:
      "https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 18, y: 78 },
    vibe: "Aviation lounge",
  },
  {
    id: "beverly-hills",
    name: "Beverly Hills",
    kicker: "02",
    tagline: "A zip code that whispers 90210",
    description:
      "Manicured palms in geometric formation. Pastel mansions hidden behind hedges of bougainvillea. The hum of a Bentley idling at a red light. This is California cinema, distilled.",
    image:
      "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 32, y: 52 },
    vibe: "Pastel opulence",
  },
  {
    id: "hollywood-sign",
    name: "Hollywood Sign",
    kicker: "03",
    tagline: "Nine letters. A million dreams.",
    description:
      "Nailed to the slope of Mount Lee since 1923, the most photographed letters in the world. From Lake Hollywood Park, the sign floats above the smog like a promise the city refuses to break.",
    image:
      "https://images.unsplash.com/photo-1597600159211-d6c104f408d1?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 45, y: 38 },
    vibe: "Iconic ascent",
  },
  {
    id: "griffith",
    name: "Griffith Observatory",
    kicker: "04",
    tagline: "The city's balcony to the cosmos",
    description:
      "Art Deco copper domes glowing at dusk. From the terrace, the LA grid ignites in slow motion — orange, then violet, then a galaxy of yellow lights. Above, Saturn waits in the telescope.",
    image:
      "https://images.unsplash.com/photo-1518756131217-31eb79b20e8f?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 50, y: 35 },
    vibe: "Stargazer's perch",
  },
  {
    id: "santa-monica",
    name: "Santa Monica Pier",
    kicker: "05",
    tagline: "The end of Route 66, the start of the Pacific",
    description:
      "A Ferris wheel turning in the salt air. The clatter of a wooden roller coaster. Kids on bikes weaving past street performers. The neon sign, photographed a billion times, still feels like a postcard you mailed yourself.",
    image:
      "https://images.unsplash.com/photo-1597176116047-876a32798fcc?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 14, y: 60 },
    vibe: "Carnival sunset",
  },
  {
    id: "venice",
    name: "Venice Beach",
    kicker: "06",
    tagline: "Skateparks, muscle and graffiti",
    description:
      "Boardwalk symphony of skaters, drum circles and oiled bodybuilders. Murals that change weekly. Surfers paddling out at dawn. A neighborhood that runs on iced coffee, sunscreen and sheer attitude.",
    image:
      "https://images.unsplash.com/photo-1503614472-8c93d56e92ce?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 16, y: 64 },
    vibe: "Boardwalk anarchy",
  },
  {
    id: "rodeo",
    name: "Rodeo Drive",
    kicker: "07",
    tagline: "Three blocks. All the labels.",
    description:
      "Terrazzo sidewalks. Window mannequins in haute couture. Ferraris double-parked outside Cartier. A choreographed daydream where every reflection is also a runway.",
    image:
      "https://images.unsplash.com/photo-1564507004663-b6dfb3c824d5?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 31, y: 53 },
    vibe: "Couture catwalk",
  },
  {
    id: "runyon",
    name: "Runyon Canyon",
    kicker: "08",
    tagline: "A workout with a view",
    description:
      "Up the dusty switchbacks of Hollywood Hills, where actors jog past tourists and dogs lead the conversation. At the top: a panorama from Downtown to Catalina, framed by chaparral and gulls.",
    image:
      "https://images.unsplash.com/photo-1583316174775-bd6dc0e9f298?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 46, y: 36 },
    vibe: "Urban summit",
  },
  {
    id: "el-matador",
    name: "El Matador Beach",
    kicker: "09",
    tagline: "A cathedral carved by the Pacific",
    description:
      "Sea stacks rising like ruins. Caves the tide carved over millennia. The kind of cove where photographers wait two hours for the right minute of golden light — and never regret it.",
    image:
      "https://images.unsplash.com/photo-1505228395891-9a51e7e86bf6?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 5, y: 50 },
    vibe: "Wild Pacific",
  },
];

export const aroundLa: Place[] = [
  {
    id: "joshua-tree",
    name: "Joshua Tree",
    kicker: "A",
    tagline: "A desert of impossible trees",
    description:
      "Two hours east, granite boulders glow rose at sunset and the Yuccas raise spiky arms to the stars. Sleep in a cabin, wake to silence, the Milky Way still bright at 5am.",
    image:
      "https://images.unsplash.com/photo-1481277542470-605612bd2d61?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 78, y: 55 },
    vibe: "Cosmic desert",
  },
  {
    id: "route-66",
    name: "Route 66",
    kicker: "B",
    tagline: "The Mother Road",
    description:
      "Neon motels, retro diners, faded gas stations. The original American highway, half-asleep and somehow more cinematic than Hollywood itself. Roll the windows down. Don't rush.",
    image:
      "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 70, y: 40 },
    vibe: "Endless asphalt",
  },
  {
    id: "palm-springs",
    name: "Palm Springs",
    kicker: "C",
    tagline: "Mid-century, mid-desert",
    description:
      "Aquamarine pools, modernist bungalows, a tramway that climbs 8,500 feet in ten minutes. By night, the San Jacinto Mountains cradle a town built for cocktails and conversations.",
    image:
      "https://images.unsplash.com/photo-1600880292203-757bb62b4baf?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 73, y: 58 },
    vibe: "Modernist oasis",
  },
  {
    id: "big-sur",
    name: "Big Sur",
    kicker: "D",
    tagline: "Where the cliffs meet the sky",
    description:
      "Highway 1 unspools above the Pacific. Bixby Bridge, redwood canyons, sea otters in kelp forests. A six-hour drive north of LA — and a hundred years away from everything.",
    image:
      "https://images.unsplash.com/photo-1556767576-5ec41e3239ea?auto=format&fit=crop&w=1600&q=80",
    coords: { x: 8, y: 18 },
    vibe: "Coastal cathedral",
  },
];

export type Restaurant = {
  id: string;
  name: string;
  kind: string;
  signature: string;
  description: string;
  image: string;
  price: string;
  hours: string;
};

export const restaurants: Restaurant[] = [
  {
    id: "in-n-out",
    name: "In-N-Out Burger",
    kind: "Cult fast food",
    signature: "Double-Double, Animal Style",
    description:
      "The California rite of passage. Fries cut on-site, milkshakes thick enough to chew, and a secret menu locals will gladly explain. Grease, mustard, joy.",
    image:
      "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1600&q=80",
    price: "$",
    hours: "10:30 — 01:00",
  },
  {
    id: "catch-la",
    name: "Catch LA",
    kind: "Rooftop seafood",
    signature: "Truffle sashimi, hellfire roll",
    description:
      "A West Hollywood rooftop swimming in fairy lights and ivy. Sushi-meets-Mediterranean plates, A-list silhouettes, and a sunset so reliable it should be on the menu.",
    image:
      "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=1600&q=80",
    price: "$$$",
    hours: "17:00 — 23:30",
  },
  {
    id: "nobu-malibu",
    name: "Nobu Malibu",
    kind: "Oceanfront omakase",
    signature: "Black cod miso, yellowtail jalapeño",
    description:
      "A glass deck cantilevered over the Pacific. The chef's omakase served as the sun melts into the horizon. Quiet luxury, loud sea, perfect rice.",
    image:
      "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=1600&q=80",
    price: "$$$$",
    hours: "12:00 — 22:30",
  },
];

export const tripStops = [
  { name: "LAX → The Proud Bird", time: "Day 0 · 21:00", note: "Wheels down. First martini." },
  { name: "Beverly Hills → Rodeo Drive", time: "Day 1 · 11:00", note: "Window-shop the unaffordable." },
  { name: "Griffith Observatory", time: "Day 1 · 18:30", note: "Sunset on the city grid." },
  { name: "Santa Monica → Venice", time: "Day 2 · 10:00", note: "Pier, boardwalk, skate park." },
  { name: "El Matador Beach", time: "Day 3 · 16:00", note: "Sea stacks at golden hour." },
  { name: "Palm Springs", time: "Day 4 · 14:00", note: "Pools and modernist bungalows." },
  { name: "Joshua Tree", time: "Day 5 · 19:00", note: "Stars, silence, sandstone." },
  { name: "Route 66 → Big Sur", time: "Day 6–7", note: "Highway 1, no playlist needed." },
];
