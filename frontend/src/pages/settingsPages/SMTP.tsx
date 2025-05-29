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
import { toast } from "sonner"; // ✅ Import toast from sonner
import api from "../api";
import { CheckCircle2 } from "lucide-react";
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
        toast.success("SMTP disabled successfully", {
  icon: <CheckCircle2 className="text-green-500" />,
}); // ✅ Using toast
      } catch (error) {
        console.error("Failed to disable SMTP:", error);
        toast.error("Something went wrong while disabling SMTP"); // ✅ Using toast
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
      toast.success("SMTP settings saved successfully", {
  icon: <CheckCircle2 className="text-green-500" />,
}); // ✅ Using toast
      setIsEditMode(false);
    } catch (error) {
      console.error("Failed to save SMTP settings", error);
      toast.error("Something went wrong while saving"); // ✅ Using toast
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
        toast.error("Something went wrong while fetching SMTP settings."); // ✅ Using toast
      }
    };
    fetchSMTPSettings();
  }, []);

  const renderField = (
    label: string,
    value: string,
    setValue: (val: string) => void,
    error?: boolean,
    isPassword?: boolean
  ) => (
    <div className="flex items-center gap-4">
      <p className="w-32 text-gray-600 text-base font-semibold">{label}:</p>
      {isEditMode ? (
        <Input
          type={isPassword ? "password" : "text"}
          value={value}
          onChange={(e) => setValue(e.target.value)}
          className={`text-gray-800 text-base font-medium w-64 ${
            error ? "border-red-500" : ""
          }`}
          placeholder={error ? "Please fill in" : ""}
        />
      ) : (
        <p className="text-gray-800 text-base font-medium w-64">
          {isPassword ? "••••••••" : value || "-"}
        </p>
      )}
    </div>
  );

  return (
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col ml-64 px-8">
        <Header title="SMTP" />
        <Card className="rounded-2xl shadow-2xl mt-6 w-[85%]">
          <CardContent className="p-6">
            <div className="flex flex-col space-y-2 text-base text-gray-800">
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
                <>
                  {renderField("Host", host, setHost, errors.host)}
                  {renderField("Port", port, setPort, errors.port)}
                  {renderField("From", from, setFrom, errors.from)}

                  <div className="flex items-center gap-4">
                    <p className="w-32 text-gray-600 text-base font-semibold">
                      Encryption:
                    </p>
                    {isEditMode ? (
                      <Select value={encryption} onValueChange={setEncryption}>
                        <SelectTrigger
                          className={`text-gray-800 text-base font-medium w-64 ${
                            errors.encryption ? "border-red-500" : ""
                          }`}
                        >
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
                    ) : (
                      <p className="text-gray-800 text-base font-medium w-64">
                        {encryption || "-"}
                      </p>
                    )}
                  </div>

                  {renderField("Hostname", hostname, setHostname, errors.hostname)}

                  <div className="flex items-center gap-4">
                    <p className="w-32 text-gray-600 text-base font-semibold">
                      Auth Method:
                    </p>
                    {isEditMode ? (
                      <Select value={authMethod} onValueChange={setAuthMethod}>
                        <SelectTrigger className="text-gray-800 text-base font-medium w-64">
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
                      <p className="text-gray-800 text-base font-medium w-64 capitalize">
                        {authMethod || "-"}
                      </p>
                    )}
                  </div>

                  {authMethod !== "none" && (
                    <>
                      {renderField("Username", username, setUserName, errors.username)}
                      {renderField(
                        "Password",
                        password,
                        setPassword,
                        errors.password,
                        true
                      )}
                    </>
                  )}
                </>
              )}

              {isSMTPEnabled && (
                <div className="flex justify-end mt-4">
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
