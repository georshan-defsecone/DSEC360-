import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";

const ScanHome = () => {
  return (
    <>
      <div className="flex h-screen text-black pt-24">
        <Sidebar settings={false} scanSettings={true} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="" />
          <Card className="h-130">
            <CardContent className="p-4 pl-8">
              <h3 className="font-bold text-xl text-gray-700">
                Defsecone Scanner
              </h3>
              <div className="flex flex-row">
                <div className="flex justify-between w-60">
                  <p className="mt-10 ml-4 text-lg font-semibold">Version:</p>
                  <p className="mt-10 ml-4 text-lg font-semibold">10.2.0</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
};

export default ScanHome;
