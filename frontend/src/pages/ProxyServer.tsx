import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";

const ProxyServer = () => {
  const [isProxyEnabled, setIsProxyEnabled] = useState(false);

  const handleSwitchChange = () => {
    setIsProxyEnabled((prev) => !prev);
  };

  return (
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="Proxy Server" />
          <Card className="">
            <CardContent className="p-2 pl-12">
              <div className="flex flex-col items-start space-y-10">
                {/* Toggle Switch */}
                <div className="flex items-center">
                  <Switch
                    id="proxyserver"
                    checked={isProxyEnabled}
                    onCheckedChange={handleSwitchChange}
                  />
                  <label
                    htmlFor="proxyserver"
                    className="ml-4 text-lg font-semibold"
                  >
                    Enable Proxy
                  </label>
                </div>

                {/* Conditional Proxy Settings */}
                {isProxyEnabled && (
                  <>
                    {/* Row 1: Host */}
                    <div className="flex items-center">
                      <p className="  w-60">Host:</p>
                      <Input type="text" className="w-60" placeholder="" />
                    </div>

                    {/* Row 2: Port */}
                    <div className="flex items-center">
                      <p className="  w-60">Port:</p>
                      <Input type="text" className="w-60" placeholder="" />
                    </div>

                    {/* Row 3: Username */}
                    <div className="flex items-center">
                      <p className="  w-60">UserName:</p>
                      <Input type="text" className="w-60" placeholder="" />
                    </div>

                    {/* Row 4: Password */}
                    <div className="flex items-center">
                      <p className="  w-60">Password:</p>
                      <Input type="text" className="w-60" placeholder="" />
                    </div>

                    {/* Row 5: Auth Method */}
                    <div className="flex items-center">
                      <p className="  w-60">AuthMethod:</p>
                      <Select>
                        <SelectTrigger className="w-[180px]">
                          <SelectValue placeholder="Select" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="autodetect">AutoDetect</SelectItem>
                          <SelectItem value="none">None</SelectItem>
                          <SelectItem value="basic">Basic</SelectItem>
                          <SelectItem value="digest">Digest</SelectItem>
                          <SelectItem value="ntlm">NTLM</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    {/* Row 6: User Agent */}
                    <div className="flex items-center">
                      <p className="  w-60">User Agent:</p>
                      <Input type="text" className="w-60" placeholder="" />
                    </div>
                  </>
                )}
                {isProxyEnabled && (
                  <Button
                    variant="outline"
                    className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition ml-auto mr-6"
                  >
                    Save
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
};

export default ProxyServer;
