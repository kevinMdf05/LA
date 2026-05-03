import IntroExperience from "@/components/IntroExperience";
import Hero from "@/components/Hero";
import Navigation from "@/components/Navigation";
import Places from "@/components/Places";
import Restaurants from "@/components/Restaurants";
import RoadTrip from "@/components/RoadTrip";
import Gallery from "@/components/Gallery";
import Conclusion from "@/components/Conclusion";
import CustomCursor from "@/components/CustomCursor";
import SmoothScroll from "@/components/SmoothScroll";
import { aroundLa, laPlaces } from "@/lib/data";

export default function Home() {
  return (
    <main className="relative">
      <SmoothScroll />
      <CustomCursor />

      <IntroExperience />

      <Navigation />
      <Hero />

      <Places
        id="places"
        kicker="The City"
        title={"Nine corners\nof Los Angeles."}
        places={laPlaces}
      />

      <Restaurants />

      <Places
        id="around"
        kicker="The Escape"
        title={"And four\ndetours\nworth the drive."}
        places={aroundLa}
      />

      <RoadTrip />
      <Gallery />
      <Conclusion />
    </main>
  );
}
