import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";

const About = () => {
  return (
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title={"About"} />
        <Card className="w-[70%] mt-10 ml-4 shadow-2xl">
          <CardContent className="w-full p-4 px-12">
            <div className="w-auto space-y-6">
              <h3 className="font-bold text-2xl text-black">Defsecone Scanner</h3>
              <div className="flex justify-between w-60">
                <p className="text-lg font-semibold">Version:</p>
                <p className="text-lg font-semibold">10.2.0</p>
              </div>
              <div className="text-md text-gray-700 pt-4">
                <p>
                  Defsecone Scanner is a powerful asset scanning and auditing tool 
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default About;
