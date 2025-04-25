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
import api from "./api";

const LDAP = () => {
  const [isEditMode, setIsEditMode] = useState(true);
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

  const handleSave = async () => {
    // Validation
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

    // If any field is missing, stop the form submission
    if (Object.values(newErrors).includes(true)) {
      return;
    }

    // If validation passed, proceed with the save logic
    const data = {
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
      // Attempt to save the settings
      await api.post("save-ldap-settings/", data);
      alert("LDAP settings saved successfully");

      // Only switch to view mode (Edit button to Show) after saving successfully
      setIsEditMode(false);
    } catch (error) {
      console.error("Failed to save LDAP settings", error);
      alert("Something went wrong");
    }
  };

  const toggleEditMode = () => {
    // If in edit mode, handle the save action first
    if (isEditMode) {
      handleSave();
    } else {
      // If not in edit mode, simply toggle to edit mode
      setIsEditMode((prev) => !prev);
    }
  };

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title="LDAP" />
        <Card >
          <CardContent className="p-3 pl-12">
            <div className="flex flex-col items-start space-y-6">
              {/* LDAP URL */}
              <div className="flex items-center">
                <p className="w-60">LDAP Server URL:</p>
                {isEditMode ? (
                  <Input
                    value={ldapUrl}
                    onChange={(e) => setLdapUrl(e.target.value)}
                    className={`w-60 ${errors.ldapUrl ? 'border-red-500' : ''}`}
                    placeholder={errors.ldapUrl ? "Please fill in" : ""}
                  />
                ) : (
                  <p className="w-60">{ldapUrl || "-"}</p>
                )}
              </div>

              {/* Base DN */}
              <div className="flex items-center">
                <p className="w-60">Base DN:</p>
                {isEditMode ? (
                  <Input
                    value={baseDn}
                    onChange={(e) => setBaseDn(e.target.value)}
                    className={`w-60 ${errors.baseDn ? 'border-red-500' : ''}`}
                    placeholder={errors.baseDn ? "Please fill in" : ""}
                  />
                ) : (
                  <p className="w-60">{baseDn || "-"}</p>
                )}
              </div>

              {/* SAM Account Name */}
              <div className="flex items-center">
                <p className="w-60">SAM Account Name:</p>
                {isEditMode ? (
                  <Input
                    value={samAccount}
                    onChange={(e) => setSamAccount(e.target.value)}
                    className={`w-60 ${errors.samAccount ? 'border-red-500' : ''}`}
                    placeholder={errors.samAccount ? "Please fill in" : ""}
                  />
                ) : (
                  <p className="w-60">{samAccount || "-"}</p>
                )}
              </div>

              {/* Bind Method */}
              <div className="flex items-center">
                <p className="w-60">Bind Method:</p>
                {isEditMode ? (
                  <Select
                    value={bindMethod}
                    onValueChange={(value) => setBindMethod(value)}
                    className={`${errors.bindMethod ? 'border-red-500' : ''}`}
                  >
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Select" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="authenticating">
                        Bind As Authenticating User
                      </SelectItem>
                      <SelectItem value="servicing">
                        Bind With Servicing Account
                      </SelectItem>
                    </SelectContent>
                  </Select>
                ) : (
                  <p className="w-60 capitalize">{bindMethod || "-"}</p>
                )}
              </div>

              {/* Bind DN (If authenticating) */}
              {bindMethod === "authenticating" && (
                <>
                  <div className="flex items-center">
                    <p className="w-60">Bind DN (if needed):</p>
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
                      <p className="w-60">{bindPassword ? "●●●●●●●" : "-"}</p>
                    )}
                  </div>
                </>
              )}

              {/* Group Base DN */}
              <div className="flex items-center">
                <p className="w-60">Group Base DN:</p>
                {isEditMode ? (
                  <Input
                    value={groupBaseDn}
                    onChange={(e) => setGroupBaseDn(e.target.value)}
                    className={`w-60 ${errors.groupBaseDn ? 'border-red-500' : ''}`}
                    placeholder={errors.groupBaseDn ? "Please fill in" : ""}
                  />
                ) : (
                  <p className="w-60">{groupBaseDn || "-"}</p>
                )}
              </div>

              {/* Admin Group Name */}
              <div className="flex items-center">
                <p className="w-60">Admin Group Name:</p>
                {isEditMode ? (
                  <Input
                    value={adminGroup}
                    onChange={(e) => setAdminGroup(e.target.value)}
                    className={`w-60 ${errors.adminGroup ? 'border-red-500' : ''}`}
                    placeholder={errors.adminGroup ? "Please fill in" : ""}
                  />
                ) : (
                  <p className="w-60">{adminGroup || "-"}</p>
                )}
              </div>

              {/* Normal Group Name */}
              <div className="flex items-center">
                <p className="w-60">Normal Group Name:</p>
                {isEditMode ? (
                  <Input
                    value={normalGroup}
                    onChange={(e) => setNormalGroup(e.target.value)}
                    className={`w-60 ${errors.normalGroup ? 'border-red-500' : ''}`}
                    placeholder={errors.normalGroup ? "Please fill in" : ""}
                  />
                ) : (
                  <p className="w-60">{normalGroup || "-"}</p>
                )}
              </div>

              {/* Use SSL */}
              <div className="flex items-center">
                <p className="w-60">Use SSL:</p>
                {isEditMode ? (
                  <Checkbox
                    checked={useSSL}
                    onCheckedChange={(checked) => setUseSSL(!!checked)}
                    className="w-5 h-5 border-gray-400 data-[state=checked]:bg-[#001f3f] data-[state=checked]:text-white"
                  />
                ) : (
                  <p className="w-60">{useSSL ? "Yes" : "No"}</p>
                )}
              </div>

              {/* Port */}
              <div className="flex items-center">
                <p className="w-60">Port:</p>
                {isEditMode ? (
                  <Input
                    type="number"
                    value={port}
                    onChange={(e) => setPort(e.target.value)}
                    className={`w-60 ${errors.port ? 'border-red-500' : ''}`}
                    placeholder={errors.port ? "Please fill in" : ""}
                  />
                ) : (
                  <p className="w-60">{port || "-"}</p>
                )}
              </div>

              {/* Save/Cancel Button */}
              <Button className="ml-auto" onClick={toggleEditMode}>
                {isEditMode ? "Save" : "Edit"}
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default LDAP;
