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
import { toast } from "sonner";
import api from "../api";
import { CheckCircle2 } from "lucide-react";

const ProxyServer = () => {
  const [isProxyEnabled, setIsProxyEnabled] = useState(false);
  const [host, setHost] = useState("");
  const [port, setPort] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [authMethod, setAuthMethod] = useState("none");
  const [userAgent, setUserAgent] = useState("");
  const [isEditMode, setIsEditMode] = useState(false);

  const [errors, setErrors] = useState({
    host: false,
    port: false,
    username: false,
    password: false,
  });

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
        setAuthMethod(data.authMethod || "none");
        setUserAgent(data.userAgent || "");
      } catch (error) {
        console.error("Failed to fetch proxy settings:", error);
        toast.error("Failed to load proxy settings.");
      }
    };

    fetchProxySettings();
  }, []);

  const handleSave = async () => {
    const newErrors = {
      host: !host,
      port: !port,
      username: authMethod !== "none" && !username,
      password: authMethod !== "none" && !password,
    };

    setErrors(newErrors);
    if (Object.values(newErrors).some(Boolean)) return;

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
      toast.success("Proxy settings saved successfully", {
  icon: <CheckCircle2 className="text-green-500" />,
});
      setIsEditMode(false);
    } catch (error) {
      console.error("Failed to save proxy settings", error);
      toast.error("Failed to save proxy settings.");
    }
  };

  const handleSwitchChange = async () => {
    const newState = !isProxyEnabled;
    setIsProxyEnabled(newState);

    if (!newState) {
      const data = {
        enabled: false,
        host,
        port,
        username,
        password,
        authMethod,
        userAgent,
      };

      try {
        await api.post("save-proxy-settings/", data);
        toast.success("Proxy disabled successfully", {
  icon: <CheckCircle2 className="text-green-500" />,
});
      } catch (error) {
        console.error("Failed to disable proxy:", error);
        toast.error("Failed to disable proxy.");
      }
    }
  };

  return (
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col ml-64 px-8">
        <Header title="Proxy Server" />
        <Card className="rounded-2xl shadow-2xl mt-6 w-[85%]">
          <CardContent className="p-6">
            <div className="flex flex-col space-y-2 text-base text-gray-800">
              <div className="flex items-center space-x-4">
                <Switch
                  id="proxyserver"
                  checked={isProxyEnabled}
                  onCheckedChange={handleSwitchChange}
                />
                <label htmlFor="proxyserver" className="text-lg font-semibold">
                  Enable Proxy
                </label>
              </div>

              {isProxyEnabled && (
                <>
                  {/* Host */}
                  <div className="flex items-center gap-4">
                    <p className="w-28 text-gray-600 text-base font-semibold">Host:</p>
                    {isEditMode ? (
                      <Input
                        value={host}
                        onChange={(e) => setHost(e.target.value)}
                        className={`text-gray-800 text-base font-medium w-64 ${errors.host ? "border-red-500" : ""}`}
                        placeholder={errors.host ? "Please fill in" : ""}
                      />
                    ) : (
                      <p className="text-gray-800 text-base font-medium w-64">{host || "-"}</p>
                    )}
                  </div>

                  {/* Port */}
                  <div className="flex items-center gap-4">
                    <p className="w-28 text-gray-600 text-base font-semibold">Port:</p>
                    {isEditMode ? (
                      <Input
                        value={port}
                        onChange={(e) => setPort(e.target.value)}
                        className={`text-gray-800 text-base font-medium w-64 ${errors.port ? "border-red-500" : ""}`}
                        placeholder={errors.port ? "Please fill in" : ""}
                      />
                    ) : (
                      <p className="text-gray-800 text-base font-medium w-64">{port || "-"}</p>
                    )}
                  </div>

                  {/* Auth Method */}
                  <div className="flex items-center gap-4">
                    <p className="w-28 text-gray-600 text-base font-semibold">Auth Method:</p>
                    {isEditMode ? (
                      <Select
                        value={authMethod}
                        onValueChange={(value) => setAuthMethod(value)}
                      >
                        <SelectTrigger className="text-gray-800 text-base font-medium w-64">
                          <SelectValue placeholder="Select" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="none">None</SelectItem>
                          <SelectItem value="autodetect">AutoDetect</SelectItem>
                          <SelectItem value="basic">Basic</SelectItem>
                          <SelectItem value="digest">Digest</SelectItem>
                          <SelectItem value="ntlm">NTLM</SelectItem>
                        </SelectContent>
                      </Select>
                    ) : (
                      <p className="text-gray-800 text-base font-medium w-64 capitalize">{authMethod || "-"}</p>
                    )}
                  </div>

                  {authMethod !== "none" && (
                    <>
                      {/* Username */}
                      <div className="flex items-center gap-4">
                        <p className="w-28 text-gray-600 text-base font-semibold">Username:</p>
                        {isEditMode ? (
                          <Input
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            className={`text-gray-800 text-base font-medium w-64 ${errors.username ? "border-red-500" : ""}`}
                            placeholder={errors.username ? "Please fill in" : ""}
                          />
                        ) : (
                          <p className="text-gray-800 text-base font-medium w-64">{username || "-"}</p>
                        )}
                      </div>

                      {/* Password */}
                      <div className="flex items-center gap-4">
                        <p className="w-28 text-gray-600 text-base font-semibold">Password:</p>
                        {isEditMode ? (
                          <Input
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            type="password"
                            className={`text-gray-800 text-base font-medium w-64 ${errors.password ? "border-red-500" : ""}`}
                            placeholder={errors.password ? "Please fill in" : ""}
                          />
                        ) : (
                          <p className="text-gray-800 text-base font-medium w-64">{password ? "••••••••" : "-"}</p>
                        )}
                      </div>
                    </>
                  )}

                  {/* User Agent */}
                  <div className="flex items-center gap-4">
                    <p className="w-28 text-gray-600 text-base font-semibold">User Agent:</p>
                    {isEditMode ? (
                      <Input
                        value={userAgent}
                        onChange={(e) => setUserAgent(e.target.value)}
                        className="text-gray-800 text-base font-medium w-64"
                      />
                    ) : (
                      <p className="text-gray-800 text-base font-medium w-64">{userAgent || "-"}</p>
                    )}
                  </div>

                  {/* Save/Edit Button */}
                  <div className="flex justify-end pt-4 w-full">
                    <Button
                      onClick={() => {
                        if (isEditMode) {
                          handleSave();
                        } else {
                          setErrors({
                            host: false,
                            port: false,
                            username: false,
                            password: false,
                          });
                          setIsEditMode(true);
                        }
                      }}
                    >
                      {isEditMode ? "Save" : "Edit"}
                    </Button>
                  </div>
                </>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default ProxyServer;
