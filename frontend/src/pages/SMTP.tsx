import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import api from "./api";

const SMTP = () => {
  const [isSMTPEnabled, setIsSMTPEnabled] = useState(false);
  const [host, setHost] = useState("");
  const [port, setPort] = useState("");
  const [from, setFrom] = useState("");
  const [username, setUserName] = useState("");
  const [password, setPassword] = useState("");
  const [authMethod, setAuthMethod] = useState("none");
  const [encryption, setEncryption] = useState("no encryption");
  const [hostname, setHostname] = useState("");

  const handleSwitchChange = async () => {
    const newState = !isSMTPEnabled;
    setIsSMTPEnabled(newState);

    if (!newState) {
      try {
        await api.post("save-smtp-settings/", { enabled: false });
        alert("SMTP disabled successfully");
      } catch (error) {
        console.error("Failed to disable SMTP:", error);
        alert("Something went wrong while disabling SMTP");
      }
    }
  };

  const handleSave = async () => {
    // Validate all fields
    if (!host || !port || !from || !encryption || !hostname || !authMethod) {
      alert("Please fill in all required fields.");
      return;
    }
  
    if (authMethod !== "none" && (!username || !password)) {
      alert("Please enter both username and password.");
      return;
    }
  
    const data = {
      enabled: true,
      host,
      port,
      from,
      encryption,
      hostname,
      authMethod,
      username: authMethod !== "none" ? username : "",
      password: authMethod !== "none" ? password : "",
    };
  
    try {
      await api.post("save-smtp-settings/", data);
      alert("SMTP settings saved successfully");
    } catch (error) {
      console.error("Failed to save SMTP settings", error);
      alert("Something went wrong while saving");
    }
  };

  return (
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="SMTP" />
          <Card>
            <CardContent className="p-2 pl-12">
              <div className="flex flex-col items-start space-y-10">
                {/* SMTP Enable Switch */}
                <div className="flex items-center">
                  <Switch
                    id="smtp"
                    checked={isSMTPEnabled}
                    onCheckedChange={handleSwitchChange}
                  />
                  <label htmlFor="smtp" className="ml-4 text-lg font-semibold">
                    Enable SMTP
                  </label>
                </div>

                {/* SMTP Settings - Conditional */}
                {isSMTPEnabled && (
                  <>
                    <div className="flex items-center">
                      <p className="w-60">Host:</p>
                      <Input
                        type="text"
                        className="w-60"
                        value={host}
                        onChange={(e) => setHost(e.target.value)}
                      />
                    </div>

                    <div className="flex items-center">
                      <p className="w-60">Port:</p>
                      <Input
                        type="text"
                        className="w-60"
                        value={port}
                        onChange={(e) => setPort(e.target.value)}
                      />
                    </div>

                    <div className="flex items-center">
                      <p className="w-60">From:</p>
                      <Input
                        type="text"
                        className="w-60"
                        value={from}
                        onChange={(e) => setFrom(e.target.value)}
                      />
                    </div>

                    <div className="flex items-center">
                      <p className="w-60">Encryption:</p>
                      <Select
                        onValueChange={(value) => setEncryption(value)}
                        value={encryption}
                      >
                        <SelectTrigger className="w-[180px]">
                          <SelectValue placeholder="Select" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="no encryption">
                            No encryption
                          </SelectItem>
                          <SelectItem value="force ssl">Force SSL</SelectItem>
                          <SelectItem value="force tls">Force TLS</SelectItem>
                          <SelectItem value="use tls if available">
                            Use TLS If Available
                          </SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="flex items-center">
                      <p className="w-60">Hostname:</p>
                      <Input
                        type="text"
                        className="w-60"
                        value={hostname}
                        onChange={(e) => setHostname(e.target.value)}
                      />
                    </div>

                    <div className="flex items-center">
                      <p className="w-60">Auth method:</p>
                      <Select
                        onValueChange={(value) => setAuthMethod(value)}
                        value={authMethod}
                      >
                        <SelectTrigger className="w-[180px]">
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
                    </div>

                    {authMethod !== "none" && (
                      <>
                        <div className="flex items-center">
                          <p className="w-60">Username:</p>
                          <Input
                            type="text"
                            className="w-60"
                            value={username}
                            onChange={(e) => setUserName(e.target.value)}
                          />
                        </div>

                        <div className="flex items-center">
                          <p className="w-60">Password:</p>
                          <Input
                            type="password"
                            className="w-60"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                          />
                        </div>
                      </>
                    )}
                  </>
                )}

                {isSMTPEnabled && (
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

export default SMTP;
