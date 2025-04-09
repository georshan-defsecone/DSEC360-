import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "../components/Header";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

const SMTP = () => {
  return (
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8">
          <Header />
          <Card className="min-h-130">
            <CardContent className="p-2 pl-12">
              <div className="flex flex-col items-start  space-y-10">
                {" "}
                {/* Add space between rows */}
                {/* Row 1 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Host:</p>{" "}
                  {/* Adjust width of label */}
                  <Input type="text" className="w-60" placeholder="" />
                </div>
                {/* Row 2 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Port:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>
                {/* Row 3 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">From:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>
                {/* Row 4 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Encryption:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>
                {/* Row 5 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Hostname:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>
                {/* Row 6 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Auth method:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>
              </div>
            </CardContent>
          </Card>
          <Button variant="outline" className="w-20 mt-6 ml-auto mr-6">
            Save
          </Button>
        </div>
      </div>
    </>
  );
};

export default SMTP;
