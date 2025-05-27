import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useState, useEffect } from "react";
import { Checkbox } from "@/components/ui/checkbox";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import api from "../api";

const LDAP = () => {
  const [isEditMode, setIsEditMode] = useState(false);
  const [isLdapEnabled, setIsLdapEnabled] = useState(false);

  const [ldapUrl, setLdapUrl] = useState("");
  const [baseDn, setBaseDn] = useState("");
  const [samAccount, setSamAccount] = useState("");
  const [bindMethod, setBindMethod] = useState("");
  const [bindDn, setBindDn] = useState("");
  const [bindPassword, setBindPassword] = useState("");
  const [groupBaseDn, setGroupBaseDn] = useState("");
  const [adminGroup, setAdminGroup] = useState("");
  const [normalGroup, setNormalGroup] = useState("");
  const [useSSL, setUseSSL] = useState(false);
  const [port, setPort] = useState("");

  const [errors, setErrors] = useState({
    ldapUrl: false,
    baseDn: false,
    samAccount: false,
    bindMethod: false,
    bindDn: false,
    bindPassword: false,
    groupBaseDn: false,
    adminGroup: false,
    normalGroup: false,
    port: false,
  });

  useEffect(() => {
    const fetchLdapSettings = async () => {
      try {
        const res = await api.get("get-ldap-settings/");
        const data = res.data;

        setIsLdapEnabled(data.enabled || false);
        setLdapUrl(data.ldapUrl || "");
        setBaseDn(data.baseDn || "");
        setSamAccount(data.samAccount || "");
        setBindMethod(data.bindMethod || "");
        setBindDn(data.bindDn || "");
        setBindPassword(data.bindPassword || "");
        setGroupBaseDn(data.groupBaseDn || "");
        setAdminGroup(data.adminGroup || "");
        setNormalGroup(data.normalGroup || "");
        setUseSSL(data.useSSL || false);
        setPort(data.port || "");
      } catch (error) {
        console.error("Failed to fetch LDAP settings:", error);
      }
    };

    fetchLdapSettings();
  }, []);

  const handleSwitchChange = async () => {
    const newState = !isLdapEnabled;
    setIsLdapEnabled(newState);
  
    // If disabling, save immediately to server
    if (!newState) {
      const data = {
        enabled: false,
        ldapUrl,
        baseDn,
        samAccount,
        bindMethod,
        bindDn,
        bindPassword,
        groupBaseDn,
        adminGroup,
        normalGroup,
        useSSL,
        port,
      };
  
      try {
        await api.post("save-ldap-settings/", data);
        alert("LDAP disabled successfully");
        setIsEditMode(false);
      } catch (error) {
        console.error("Failed to disable LDAP:", error);
        alert("Something went wrong while disabling LDAP");
      }
    } else {
      // Just enable in UI; don't save yet
      setIsEditMode(true);
    }
  };
  

  const handleSave = async () => {
    if (!isLdapEnabled) {
      alert("Please enable LDAP before saving.");
      return;
    }

    const newErrors = {
      ldapUrl: !ldapUrl,
      baseDn: !baseDn,
      samAccount: !samAccount,
      bindMethod: !bindMethod,
      bindDn: bindMethod === "authenticating" && !bindDn,
      bindPassword: bindMethod === "authenticating" && !bindPassword,
      groupBaseDn: !groupBaseDn,
      adminGroup: !adminGroup,
      normalGroup: !normalGroup,
      port: !port,
    };

    setErrors(newErrors);

    if (Object.values(newErrors).some(Boolean)) return;

    const data = {
      enabled: isLdapEnabled,
      ldapUrl,
      baseDn,
      samAccount,
      bindMethod,
      bindDn,
      bindPassword,
      groupBaseDn,
      adminGroup,
      normalGroup,
      useSSL,
      port,
    };

    try {
      await api.post("save-ldap-settings/", data);
      alert("LDAP settings saved successfully");
      setIsEditMode(false);
    } catch (error) {
      console.error("Failed to save LDAP settings", error);
      alert("Something went wrong");
    }
  };

  return (
    <div className="flex h-screen text-gray-800 pt-24 font-sans">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title="LDAP" />
        <Card className="bg-white shadow-2xl rounded-lg border border-gray-300 w-[96%]">
          <CardContent className="p-6">
            <div className="flex flex-col items-start space-y-6 font-medium">

              {/* Enable LDAP Switch */}
              <div className="flex items-center mb-4">
                <Switch
                  id="ldapserver"
                  checked={isLdapEnabled}
                  onCheckedChange={handleSwitchChange}
                />
                <label htmlFor="ldapserver" className="ml-4 text-lg font-semibold">
                  Enable LDAP
                </label>
              </div>

              {isLdapEnabled && (
                <>
                  {[ 
                    { label: "LDAP Server URL", value: ldapUrl, setter: setLdapUrl, error: errors.ldapUrl },
                    { label: "Base DN", value: baseDn, setter: setBaseDn, error: errors.baseDn },
                    { label: "SAM Account Name", value: samAccount, setter: setSamAccount, error: errors.samAccount },
                    { label: "Group Base DN", value: groupBaseDn, setter: setGroupBaseDn, error: errors.groupBaseDn },
                    { label: "Admin Group Name", value: adminGroup, setter: setAdminGroup, error: errors.adminGroup },
                    { label: "Normal Group Name", value: normalGroup, setter: setNormalGroup, error: errors.normalGroup },
                    { label: "Port", value: port, setter: setPort, error: errors.port, type: "number" },
                  ].map(({ label, value, setter, error, type = "text" }) => (
                    <div className="flex items-center" key={label}>
                      <p className="w-60">{label}:</p>
                      {isEditMode ? (
                        <Input
                          type={type}
                          value={value}
                          onChange={(e) => setter(e.target.value)}
                          className={`w-60 ${error ? 'border-red-500' : ''}`}
                          placeholder={error ? "Please fill in" : ""}
                        />
                      ) : (
                        <p className="w-60">{value || "-"}</p>
                      )}
                    </div>
                  ))}

                  <div className="flex items-center">
                    <p className="w-60">Bind Method:</p>
                    {isEditMode ? (
                      <Select value={bindMethod} onValueChange={setBindMethod}>
                        <SelectTrigger className="w-[180px]">
                          <SelectValue placeholder="Select" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="authenticating">Bind As Authenticating User</SelectItem>
                          <SelectItem value="servicing">Bind With Servicing Account</SelectItem>
                        </SelectContent>
                      </Select>
                    ) : (
                      <p className="w-60 capitalize">{bindMethod || "-"}</p>
                    )}
                  </div>

                  {bindMethod === "authenticating" && (
                    <>
                      <div className="flex items-center">
                        <p className="w-60">Bind DN:</p>
                        {isEditMode ? (
                          <Input
                            value={bindDn}
                            onChange={(e) => setBindDn(e.target.value)}
                            className={`w-60 ${errors.bindDn ? 'border-red-500' : ''}`}
                            placeholder={errors.bindDn ? "Please fill in" : ""}
                          />
                        ) : (
                          <p className="w-60">{bindDn || "-"}</p>
                        )}
                      </div>
                      <div className="flex items-center">
                        <p className="w-60">Bind Password:</p>
                        {isEditMode ? (
                          <Input
                            type="password"
                            value={bindPassword}
                            onChange={(e) => setBindPassword(e.target.value)}
                            className={`w-60 ${errors.bindPassword ? 'border-red-500' : ''}`}
                            placeholder={errors.bindPassword ? "Please fill in" : ""}
                          />
                        ) : (
                          <p className="w-60">{bindPassword ? "••••••••" : "-"}</p>
                        )}
                      </div>
                    </>
                  )}

                  <div className="flex items-center">
                    <p className="w-60">Use SSL:</p>
                    {isEditMode ? (
                      <Checkbox
                        checked={useSSL}
                        onCheckedChange={(checked) => setUseSSL(!!checked)}
                      />
                    ) : (
                      <p className="w-60">{useSSL ? "Yes" : "No"}</p>
                    )}
                  </div>

                  <Button
                    className="ml-auto"
                    onClick={() => {
                      if (isEditMode) {
                        handleSave();
                      } else {
                        setErrors({});
                        setIsEditMode(true);
                      }
                    }}
                    disabled={!isLdapEnabled}
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
  );
};

export default LDAP;
