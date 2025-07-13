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
import { toast } from "sonner";  // <-- import toast
import { CheckCircle2 } from "lucide-react";

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
        toast.error("Failed to load LDAP settings.");
      }
    };

    fetchLdapSettings();
  }, []);

  const handleSwitchChange = async () => {
    const newState = !isLdapEnabled;
    setIsLdapEnabled(newState);

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
        toast.success("LDAP disabled successfully", {
  icon: <CheckCircle2 className="text-green-500" />,
});
        setIsEditMode(false);
      } catch (error) {
        console.error("Failed to disable LDAP:", error);
        toast.error("Something went wrong while disabling LDAP");
      }
    } else {
      setIsEditMode(true);
    }
  };

  const handleSave = async () => {
    if (!isLdapEnabled) {
      toast.error("Please enable LDAP before saving.");
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
      toast.success("LDAP settings saved successfully", {
  icon: <CheckCircle2 className="text-green-500" />,
});
      setIsEditMode(false);
    } catch (error) {
      console.error("Failed to save LDAP settings", error);
      toast.error("Something went wrong");
    }
  };

  return (
    <div className="flex h-screen pt-24 font-sans  text-gray-800">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col pl-72 pr-12">
        <Header title="LDAP" />
        <Card className="rounded-none shadow-2xl mt-6 w-[86%]">
          <CardContent className="p-6 space-y-6 text-sm">
            <div className="flex items-center space-x-4">
              <Switch
                id="ldapserver"
                checked={isLdapEnabled}
                onCheckedChange={handleSwitchChange}
              />
              <label htmlFor="ldapserver" className="text-lg font-semibold">
                Enable LDAP
              </label>
            </div>

            {isLdapEnabled && (
              <div className="space-y-4">
                {[
                  { label: "LDAP Server URL", value: ldapUrl, setter: setLdapUrl, error: errors.ldapUrl },
                  { label: "Base DN", value: baseDn, setter: setBaseDn, error: errors.baseDn },
                  { label: "SAM Account Name", value: samAccount, setter: setSamAccount, error: errors.samAccount },
                  { label: "Group Base DN", value: groupBaseDn, setter: setGroupBaseDn, error: errors.groupBaseDn },
                  { label: "Admin Group Name", value: adminGroup, setter: setAdminGroup, error: errors.adminGroup },
                  { label: "Normal Group Name", value: normalGroup, setter: setNormalGroup, error: errors.normalGroup },
                  { label: "Port", value: port, setter: setPort, error: errors.port, type: "number" },
                ].map(({ label, value, setter, error, type = "text" }) => (
                  <div className="flex items-center gap-6" key={label}>
                    <p className="w-28 text-gray-600 text-base font-semibold">{label}:</p>
                    {isEditMode ? (
                      <Input
                        type={type}
                        value={value}
                        onChange={(e) => setter(e.target.value)}
                        className={`text-gray-800 text-base font-medium w-64 ${error ? "border-red-500" : ""}`}
                        placeholder={error ? "Please fill in" : ""}
                      />
                    ) : (
                      <p className="text-gray-800 text-base font-medium w-64">{value || "-"}</p>
                    )}
                  </div>
                ))}

                <div className="flex items-center gap-6">
                  <p className="w-28 text-gray-600 text-base font-semibold">Bind Method:</p>
                  {isEditMode ? (
                    <Select value={bindMethod} onValueChange={setBindMethod}>
                      <SelectTrigger className="text-gray-800 text-base font-medium w-64">
                        <SelectValue placeholder="Select" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="authenticating">Bind As Authenticating User</SelectItem>
                        <SelectItem value="servicing">Bind With Servicing Account</SelectItem>
                      </SelectContent>
                    </Select>
                  ) : (
                    <p className="text-gray-800 text-base font-medium w-64 capitalize">{bindMethod || "-"}</p>
                  )}
                </div>

                {bindMethod === "authenticating" && (
                  <>
                    <div className="flex items-center gap-6">
                      <p className="w-28 text-gray-600 text-base font-semibold">Bind DN:</p>
                      {isEditMode ? (
                        <Input
                          value={bindDn}
                          onChange={(e) => setBindDn(e.target.value)}
                          className={`text-gray-800 text-base font-medium w-64 ${errors.bindDn ? "border-red-500" : ""}`}
                          placeholder={errors.bindDn ? "Please fill in" : ""}
                        />
                      ) : (
                        <p className="text-gray-800 text-base font-medium w-64">{bindDn || "-"}</p>
                      )}
                    </div>
                    <div className="flex items-center gap-6">
                      <p className="w-28 text-gray-600 text-base font-semibold">Bind Password:</p>
                      {isEditMode ? (
                        <Input
                          type="password"
                          value={bindPassword}
                          onChange={(e) => setBindPassword(e.target.value)}
                          className={`text-gray-800 text-base font-medium w-64 ${errors.bindPassword ? "border-red-500" : ""}`}
                          placeholder={errors.bindPassword ? "Please fill in" : ""}
                        />
                      ) : (
                        <p className="text-gray-800 text-base font-medium w-64">{bindPassword ? "••••••••" : "-"}</p>
                      )}
                    </div>
                  </>
                )}

                <div className="flex items-center gap-6">
                  <p className="w-28 text-gray-600 text-base font-semibold">Use SSL:</p>
                  {isEditMode ? (
                    <Checkbox
                      checked={useSSL}
                      onCheckedChange={(checked) => setUseSSL(!!checked)}
                    />
                  ) : (
                    <p className="text-gray-800 text-base font-medium w-64">{useSSL ? "Yes" : "No"}</p>
                  )}
                </div>

                <div className="flex justify-end pt-4">
                  <Button
                    className="w-28"
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
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default LDAP;
