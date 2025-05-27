import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";

const Advanced = () => {
  const tabNames = [
    "user interface",
    "scanning",
    "logging",
    "performance",
    "security",
    "miscellanous",
    "custom",
  ];

  return (
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />

      <div className="flex-1 flex flex-col ml-64 px-8">
        <Header title="Advanced" />

        <Card className="rounded-2xl shadow-2xl mt-6 w-[96%]">
          <CardContent className="p-6 w-full">
            <Tabs defaultValue="user interface" className="w-full">
              <TabsList className="grid grid-cols-7 gap-2 w-full bg-transparent border-none shadow-none">
                {tabNames.map((tab) => (
                  <TabsTrigger
                    key={tab}
                    value={tab}
                    className="text-sm text-gray-700 hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-2 py-2 rounded-md font-medium capitalize text-center"
                  >
                    {tab}
                  </TabsTrigger>
                ))}
              </TabsList>

              <TabsContent value="user interface" className="pt-6">
                <div className="text-center text-gray-600">
                  User Interface settings will appear here.
                </div>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Advanced;
