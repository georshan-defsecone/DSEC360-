import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs"

const Advanced = () => {
  return (
    <>
      <div className="flex h-screen text-black pt-24">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="Advanced" /> 
          <Card className="h-130">
            <CardContent className="p-4 pl-8 w-full">
            <Tabs defaultValue="account" className="w-full">
      <TabsList className="flex justify-evenly gap-4 bg-white">
        <TabsTrigger value="user interface" className="hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-4 py-2 rounded">User Interface</TabsTrigger>
        <TabsTrigger value="scanning" className="hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-4 py-2 rounded">Scanning</TabsTrigger>
        <TabsTrigger value="logging" className="hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-4 py-2 rounded">Logging</TabsTrigger>
        <TabsTrigger value="performance" className="hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-4 py-2 rounded">Performance</TabsTrigger>
        <TabsTrigger value="security" className="hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-4 py-2 rounded">Security</TabsTrigger>
        <TabsTrigger value="miscellanous" className="hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-4 py-2 rounded">Miscellanous</TabsTrigger>
        <TabsTrigger value="custom" className="hover:bg-black hover:text-white data-[state=active]:bg-black data-[state=active]:text-white transition-colors duration-200 px-4 py-2 rounded">Custom</TabsTrigger>
      </TabsList>
      </Tabs>
              <div className="flex flex-row"></div>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
};

export default Advanced;
