import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useState, useEffect } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import api from "../api";

const SMTP = () => {
  const [isSMTPEnabled, setIsSMTPEnabled] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);

  const [host, setHost] = useState("");
  const [port, setPort] = useState("");
  const [from, setFrom] = useState("");
  const [username, setUserName] = useState("");
  const [password, setPassword] = useState("");
  const [authMethod, setAuthMethod] = useState("none");
  const [encryption, setEncryption] = useState("no encryption");
  const [hostname, setHostname] = useState("");

  const [errors, setErrors] = useState({
    host: false,
    port: false,
    from: false,
    username: false,
    password: false,
    encryption: false,
    hostname: false,
  });

  const handleSwitchChange = async () => {
    const newState = !isSMTPEnabled;
    setIsSMTPEnabled(newState);
    setIsEditMode(newState);
    if (!newState) {
      try {
        await api.post("save-smtp-settings/", {
          enabled: false,
          host,
          port,
          from,
          encryption,
          hostname,
          authMethod,
          username: authMethod !== "none" ? username : "",
          password: authMethod !== "none" ? password : "",
        });
        alert("SMTP disabled successfully");
      } catch (error) {
        console.error("Failed to disable SMTP:", error);
        alert("Something went wrong while disabling SMTP");
      }
    }
  };

  const handleSave = async () => {
    const newErrors = {
      host: !host,
      port: !port,
      from: !from,
      username: authMethod !== "none" && !username,
      password: authMethod !== "none" && !password,
      encryption: !encryption,
      hostname: !hostname,
    };
    setErrors(newErrors);
    const hasError = Object.values(newErrors).some(Boolean);
    if (hasError) return;
    try {
      await api.post("save-smtp-settings/", {
        enabled: true,
        host,
        port,
        from,
        encryption,
        hostname,
        authMethod,
        username: authMethod !== "none" ? username : "",
        password: authMethod !== "none" ? password : "",
      });
      alert("SMTP settings saved successfully");
      setIsEditMode(false);
    } catch (error) {
      console.error("Failed to save SMTP settings", error);
      alert("Something went wrong while saving");
    }
  };

  useEffect(() => {
    const fetchSMTPSettings = async () => {
      try {
        const response = await api.get("get-smtp-settings/");
        const data = response.data;
        setIsSMTPEnabled(data.enabled || false);
        setHost(data.host || "");
        setPort(data.port || "");
        setFrom(data.from || "");
        setEncryption(data.encryption || "no encryption");
        setHostname(data.hostname || "");
        setAuthMethod(data.authMethod || "none");
        setUserName(data.username || "");
        setPassword(data.password || "");
        setIsEditMode(false);
      } catch (error) {
        console.error("Failed to load SMTP settings", error);
        alert("Something went wrong while fetching SMTP settings.");
      }
    };
    fetchSMTPSettings();
  }, []);

  return (
    <div className="flex h-screen text-black font-sans pt-24">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title="SMTP" />
        <Card className="rounded-2xl shadow-lg border border-gray-200 w-[96%]">
          <CardContent className="p-6">
            <div className="space-y-8">
              {/* Enable Switch */}
              <div className="flex items-center space-x-4">
                <Switch
                  id="smtp"
                  checked={isSMTPEnabled}
                  onCheckedChange={handleSwitchChange}
                />
                <label htmlFor="smtp" className="text-lg font-semibold">
                  Enable SMTP
                </label>
              </div>

              {isSMTPEnabled && (
                <div className="grid grid-cols-[200px_1fr] gap-4 items-center">
                  {/* Host */}
                  <label>Host</label>
                  {isEditMode ? (
                    <Input
                      className={`w-64 ${errors.host ? "border-red-500" : ""}`}
                      value={host}
                      onChange={(e) => setHost(e.target.value)}
                      placeholder={errors.host ? "Please fill in" : ""}
                    />
                  ) : (
                    <p>{host}</p>
                  )}

                  {/* Port */}
                  <label>Port</label>
                  {isEditMode ? (
                    <Input
                      className={`w-64 ${errors.port ? "border-red-500" : ""}`}
                      value={port}
                      onChange={(e) => setPort(e.target.value)}
                      placeholder={errors.port ? "Please fill in" : ""}
                    />
                  ) : (
                    <p>{port}</p>
                  )}

                  {/* From */}
                  <label>From</label>
                  {isEditMode ? (
                    <Input
                      className={`w-64 ${errors.from ? "border-red-500" : ""}`}
                      value={from}
                      onChange={(e) => setFrom(e.target.value)}
                      placeholder={errors.from ? "Please fill in" : ""}
                    />
                  ) : (
                    <p>{from}</p>
                  )}

                  {/* Encryption */}
                  <label>Encryption</label>
                  {isEditMode ? (
                    <Select
                      onValueChange={setEncryption}
                      value={encryption}
                    >
                      <SelectTrigger
                        className={`w-64 ${errors.encryption ? "border-red-500" : ""}`}
                      >
                        <SelectValue placeholder="Select" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="no encryption">No encryption</SelectItem>
                        <SelectItem value="force ssl">Force SSL</SelectItem>
                        <SelectItem value="force tls">Force TLS</SelectItem>
                        <SelectItem value="use tls if available">Use TLS If Available</SelectItem>
                      </SelectContent>
                    </Select>
                  ) : (
                    <p>{encryption}</p>
                  )}

                  {/* Hostname */}
                  <label>Hostname</label>
                  {isEditMode ? (
                    <Input
                      className={`w-64 ${errors.hostname ? "border-red-500" : ""}`}
                      value={hostname}
                      onChange={(e) => setHostname(e.target.value)}
                      placeholder={errors.hostname ? "Please fill in" : ""}
                    />
                  ) : (
                    <p>{hostname}</p>
                  )}

                  {/* Auth Method */}
                  <label>Auth Method</label>
                  {isEditMode ? (
                    <Select onValueChange={setAuthMethod} value={authMethod}>
                      <SelectTrigger className="w-64">
                        <SelectValue placeholder="Select" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="none">None</SelectItem>
                        <SelectItem value="plain">Plain</SelectItem>
                        <SelectItem value="login">Login</SelectItem>
                        <SelectItem value="ntlm">NTLM</SelectItem>
                        <SelectItem value="cram md5">CRAM MD5</SelectItem>
                      </SelectContent>
                    </Select>
                  ) : (
                    <p>{authMethod}</p>
                  )}

                  {/* Username & Password - only if authMethod !== none */}
                  {authMethod !== "none" && (
                    <>
                      <label>Username</label>
                      {isEditMode ? (
                        <Input
                          className={`w-64 ${errors.username ? "border-red-500" : ""}`}
                          value={username}
                          onChange={(e) => setUserName(e.target.value)}
                          placeholder={errors.username ? "Please fill in" : ""}
                        />
                      ) : (
                        <p>{username}</p>
                      )}

                      <label>Password</label>
                      {isEditMode ? (
                        <Input
                          type="password"
                          className={`w-64 ${errors.password ? "border-red-500" : ""}`}
                          value={password}
                          onChange={(e) => setPassword(e.target.value)}
                          placeholder={errors.password ? "Please fill in" : ""}
                        />
                      ) : (
                        <p>••••••••</p>
                      )}
                    </>
                  )}
                </div>
              )}

              {/* Save/Edit Button */}
              {isSMTPEnabled && (
                <div className="flex justify-end">
                  <Button
                    variant="outline"
                    className="bg-black text-white hover:bg-gray-800"
                    onClick={() => {
                      if (isEditMode) {
                        handleSave();
                      } else {
                        setErrors({
                          host: false,
                          port: false,
                          from: false,
                          username: false,
                          password: false,
                          encryption: false,
                          hostname: false,
                        });
                        setIsEditMode(true);
                      }
                    }}
                  >
                    {isEditMode ? "Save" : "Edit"}
                  </Button>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SMTP;
