import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";

const ScanHome = () => {
  return (
    <>
      <div className="flex h-screen text-black pt-24">
        <Sidebar settings={false} scanSettings={true} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title={"Scan Home"} />
          <div className="flex flex-col justify-center items-center gap-3 pb-45 h-screen">
            <h1 className="text-3xl font-normal">Get started by <span className="text-decoration-line: underline">running a scan.</span></h1>
            <h2 className="text-2xl font-normal">Choose a scan type from the sidebar to begin.</h2>
          </div>
        </div>
      </div>
    </>
  );
};

export default ScanHome;
