import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Button } from "@/components/ui/button";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import api from "./api";

const ProxyServer = () => {
  const [isProxyEnabled, setIsProxyEnabled] = useState(false);
  const [host, setHost] = useState("");
  const [port, setPort] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [authMethod, setAuthMethod] = useState("None");
  const [userAgent, setUserAgent] = useState("");

  useEffect(() => {
    const fetchProxySettings = async () => {
      try {
        const res = await api.get("get-proxy-settings/");
        const data = res.data;

        setIsProxyEnabled(data.enabled || false);
        setHost(data.host || "");
        setPort(data.port || "");
        setUsername(data.username || "");
        setPassword(data.password || "");
        setAuthMethod(data.authMethod || "");
        setUserAgent(data.userAgent || "");
      } catch (error) {
        console.error("Failed to fetch proxy settings:", error);
      }
    };

    fetchProxySettings();
  }, []);

  const handleSave = async () => {

    if (!host || !port || !username || !password || !authMethod) {
      alert("Please fill in all required fields.");
      return;
    }
  
    const data = {
      enabled: isProxyEnabled,
      host,
      port,
      username,
      password,
      authMethod,
      userAgent,
    };
    try {
      await api.post("save-proxy-settings/", data);
      alert("Proxy settings saved successfully ");
    } catch (error) {
      console.error("Failed to save proxy settings", error);
      alert("Something went wrong ");
    }
  };

  const handleSwitchChange = async () => {
    const newState = !isProxyEnabled;
    setIsProxyEnabled(newState);
  
    if (!newState) {
      // If toggling OFF, inform backend immediately
      try {
        await api.post("save-proxy-settings/", { enabled: false });
        alert("Proxy disabled successfully");
      } catch (error) {
        console.error("Failed to disable proxy:", error);
        alert("Something went wrong while disabling proxy");
      }
    }
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
                      <p className="  w-60">Host:<span className="text-red-500">*</span></p>
                      <Input
                        value={host}
                        onChange={(e) => setHost(e.target.value)}
                        className="w-60"
                      />
                    </div>

                    {/* Row 2: Port */}
                    <div className="flex items-center">
                      <p className="  w-60">Port:<span className="text-red-500">*</span></p>
                      <Input
                        value={port}
                        onChange={(e) => setPort(e.target.value)}
                        className="w-60"
                      />
                    </div>

                    {/* Row 3: Username */}

                    {/* Row 5: Auth Method */}
                    <div className="flex items-center">
                      <p className="  w-60">AuthMethod:</p>
                      <Select
                        value={authMethod}
                        onValueChange={(value) => setAuthMethod(value)}
                      >
                        <SelectTrigger className="w-[180px]">
                          <SelectValue placeholder="Select" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="autodetect">None</SelectItem>
                          <SelectItem value="none">AutoDetect</SelectItem>
                          <SelectItem value="basic">Basic</SelectItem>
                          <SelectItem value="digest">Digest</SelectItem>
                          <SelectItem value="ntlm">NTLM</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="flex items-center">
                      <p className="  w-60">UserName:<span className="text-red-500">*</span></p>
                      <Input
                        value={username}
                        onChange={(e) => setUsername(e.target.value)}
                        className="w-60"
                      />
                    </div>

                    {/* Row 4: Password */}
                    <div className="flex items-center">
                      <p className="  w-60">Password:<span className="text-red-500">*</span></p>
                      <Input
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="w-60"
                      />
                    </div>

                    {/* Row 6: User Agent */}
                    <div className="flex items-center">
                      <p className="  w-60">User Agent:</p>
                      <Input
                        value={userAgent}
                        onChange={(e) => setUserAgent(e.target.value)}
                        className="w-60"
                      />
                    </div>
                  </>
                )}
                {isProxyEnabled && (
                  <Button
                    variant="outline"
                    className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition ml-auto mr-6"
                    onClick={handleSave}
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
