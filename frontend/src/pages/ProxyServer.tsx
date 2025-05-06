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

    const hasError = Object.values(newErrors).some(Boolean);
    if (hasError) {
      return; // No alert needed now
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
      alert("Proxy settings saved successfully");
      setIsEditMode(false);
    } catch (error) {
      console.error("Failed to save proxy settings", error);
      alert("Something went wrong");
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
        alert("Proxy disabled successfully");
      } catch (error) {
        console.error("Failed to disable proxy:", error);
        alert("Something went wrong while disabling proxy");
      }
    }
  };

  return (
    <>
      <div className="flex h-screen text-black pt-24">
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

              {isProxyEnabled && (
                <>
                  {/* Host */}
                  <div className="flex items-center">
                    <p className="w-60">
                      Host:<span className="text-red-500">*</span>
                    </p>
                    {isEditMode ? (
                      <Input
                        value={host}
                        onChange={(e) => setHost(e.target.value)}
                        className={`w-60 ${errors.host ? "border-red-500" : ""}`}
                        placeholder={errors.host ? "Please fill in" : ""}
                      />
                    ) : (
                      <p className="w-60">{host || "-"}</p>
                    )}
                  </div>

                  {/* Port */}
                  <div className="flex items-center">
                    <p className="w-60">
                      Port:<span className="text-red-500">*</span>
                    </p>
                    {isEditMode ? (
                      <Input
                        value={port}
                        onChange={(e) => setPort(e.target.value)}
                        className={`w-60 ${errors.port ? "border-red-500" : ""}`}
                        placeholder={errors.port ? "Please fill in" : ""}
                      />
                    ) : (
                      <p className="w-60">{port || "-"}</p>
                    )}
                  </div>

                  {/* Auth Method */}
                  <div className="flex items-center">
                    <p className="w-60">Auth Method:</p>
                    {isEditMode ? (
                      <Select
                        value={authMethod}
                        onValueChange={(value) => setAuthMethod(value)}
                      >
                        <SelectTrigger className="w-[180px]">
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
                      <p className="w-60 capitalize">{authMethod || "-"}</p>
                    )}
                  </div>

                  {authMethod !== "none" && (
                    <>
                      {/* Username */}
                      <div className="flex items-center">
                        <p className="w-60">
                          Username:<span className="text-red-500">*</span>
                        </p>
                        {isEditMode ? (
                          <Input
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            className={`w-60 ${errors.username ? "border-red-500" : ""}`}
                            placeholder={errors.username ? "Please fill in" : ""}
                          />
                        ) : (
                          <p className="w-60">{username || "-"}</p>
                        )}
                      </div>

                      {/* Password */}
                      <div className="flex items-center">
                        <p className="w-60">
                          Password:<span className="text-red-500">*</span>
                        </p>
                        {isEditMode ? (
                          <Input
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className={`w-60 ${errors.password ? "border-red-500" : ""}`}
                            type="password"
                            placeholder={errors.password ? "Please fill in" : ""}
                          />
                        ) : (
                          <p className="w-60">{password ? "••••••••" : "-"}</p>
                        )}
                      </div>
                    </>
                  )}

                  {/* User Agent */}
                  <div className="flex items-center">
                    <p className="w-60">User Agent:</p>
                    {isEditMode ? (
                      <Input
                        value={userAgent}
                        onChange={(e) => setUserAgent(e.target.value)}
                        className="w-60"
                      />
                    ) : (
                      <p className="w-60">{userAgent || "-"}</p>
                    )}
                  </div>

                  {/* Save/Edit Button */}
                  <Button
                    className="ml-auto"
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
                </>
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
