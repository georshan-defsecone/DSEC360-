import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import Breadcrumbs from "@/components/ui/Breadcrumbs";
import { ElevatePrivilegeForm } from "@/components/ElevatePrivilegeForm";
import { Card, CardContent } from "@/components/ui/card";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

import api from "../api";

const ScanCAFirewall = () => {
  const [complianceData, setComplianceData] = useState([]);
  const [errors, setErrors] = useState("");

  const formPages = [
    "General Info",
    "Target Details",
    "Compliance Info",
    "Scan Settings",
  ];

  const [page, setPage] = useState(1);
  const [formData, setFormData] = useState({
    // General Info
    scanName: "",
    projectName: "",
    description: "",

    // Target Details
    auditMethod: "",
    OS: "",
    target: "",
    elevatePrivilege: "",
    authMethod: "",
    username: "",
    password: "",
    domain: "",
    ntlmHash: "",
    lmHash: "",
    kdc: "",
    kdcPort: "",
    kdcTransport: "",
    certificate: "",
    publicKey: "",
    privateKeyPassphrase: "",
    port: "",
    clientVersion: "",
    attemptLeastPrivilege: "",

    EP_escalationAccount: "", // .k5login, dzdo
    EP_escalationPassword: "", // .k5login, dzdo, su, su+sudo
    EP_dzdoDirectory: "", // dzdo
    EP_suDirectory: "", // su
    EP_pbrunDirectory: "", // pbrun
    EP_su_sudoDirectory: "", // su+sudo
    EP_su_login: "", //su
    EP_su_user: "", // su+sudo
    EP_sudoUser: "", // su+sudo
    EPsshUserPassword: "", // pbrun
    EPenablePassword: "", // Cisco enable

    //global credentials settings
    globalCredentials: {
      neverSendCredentials: "false",
      dontUseNTLMv1: "false",
      startRemoteRegistryService: "false",
      enableAdministrativeShares: "false",
      startServerService: "false",
    },

    //Get compliance info
    complianceCategory: "",
    complianceSecurityStandard: "",

    //Scan settings
    schedule: "",
    scheduleFrequency: "",
    scheduleStartDate: "",
    scheduleStartTime: "",
    scheduleTimezone: "",
    notification: "",
    notificationEmail: "",
  });

  const validatePage1 = () => {
    return (
      formData.scanName.trim() !== "" &&
      formData.projectName.trim() !== "" &&
      formData.description.trim() !== ""
    );
  };
  
  const validatePage2 = () => {
    if (!formData.auditMethod || !formData.OS) return false;
  
    if (formData.auditMethod === "remoteAccess") {
      if (!formData.target) return false;
      if (!formData.authMethod) return false;
  
      // Validate based on authentication method
      switch (formData.authMethod) {
        case "password":
          return formData.username && formData.password;
        case "ntlm":
          return formData.username && formData.ntlmHash && formData.domain;
        case "kerberos":
          return (
            formData.username &&
            formData.password &&
            formData.kdc &&
            formData.kdcPort &&
            formData.domain
          );
        case "lm":
          return formData.username && formData.lmHash && formData.domain;
        default:
          return false;
      }
    }
  
    return true; // For agent and uploadConfig methods
  };
  
  const validatePage3 = () => {
    return (
      formData.complianceCategory !== "" &&
      formData.complianceSecurityStandard !== ""
    );
  };
  
  const validatePage4 = () => {
    if (formData.schedule !== "true" && formData.notification !== "true") {
      setErrors("Please enable either scheduling or notifications");
      return false;
    }
  
    // Validate schedule settings
    if (formData.schedule === "true") {
      if (!formData.scheduleFrequency || !formData.scheduleStartDate || !formData.scheduleStartTime || !formData.scheduleTimezone) {
        setErrors("Please fill in all schedule fields");
        return false;
      }
    }
  
    // Validate notification settings
    if (formData.notification === "true") {
      if (!formData.notificationEmail) {
        setErrors("Please enter an email address");
        return false;
      }
      // Basic email validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(formData.notificationEmail)) {
        setErrors("Please enter a valid email address");
        return false;
      }
    }
  
    // If all validations pass
    return true;
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await api.get("/scans/compliance/configaudit/firewall/");
        console.log("Fetched data:", response.data);
        setComplianceData(response.data);
      } catch (error) {
        console.error("Error fetching compliance data:", error);
        setErrors("Error fetching compliance data. Please try again later.");
      }
    };

    fetchData();
  }, []);

  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | string,
    field?: string
  ) => {
    if (typeof e === "string" && field) {
      setFormData((prev) => ({
        ...prev,
        [field]: e,
      }));
    } else if (typeof e === "object" && "target" in e) {
      const { name, value } = e.target;
      setFormData((prev) => ({
        ...prev,
        [name]: value,
      }));
    }
  };

  const handleNestedInputChange = (
    field: string,
    nestedField: string,
    value: string
  ) => {
    setFormData((prev) => {
      const updatedField = {
        ...((prev[field as keyof typeof prev] || {}) as Record<string, string>),
        [nestedField]: value,
      };

      return {
        ...prev,
        [field]: updatedField,
      };
    });
  };

  const nextPage = () => {
    let isValid = false;

    switch (page) {
      case 1:
        isValid = validatePage1();
        break;
      case 2:
        isValid = validatePage2();
        break;
      case 3:
        isValid = validatePage3();
        break;
      case 4:
        isValid = validatePage4();
        break;
      default:
        isValid = false;
    }

    if (!isValid) {
      setErrors("Please fill in all required fields before proceeding.");
      return;
    }

    setErrors(""); // Clear any existing errors
    if (page < 4) setPage((prev) => prev + 1);
  };

  const prevPage = () => {
    if (page > 1) setPage((prev) => prev - 1);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!validatePage4()) {
      return;
    }

    setErrors(""); // Clear any existing errors

    console.log("Form submitted:", formData);
    // Add your submission logic here
  };

  const renderError = () => {
    if (errors) {
      return (
        <div className="mb-4 p-2 bg-red-100 border border-red-400 text-red-700 rounded">
          {errors}
        </div>
      );
    }
    return null;
  };

  const renderPage = () => {
    switch (page) {
      case 1:
        return (
          <div className="space-y-4">
            {renderError()}
            <h2 className="text-xl font-semibold">General Information</h2>

            <div className="flex items-center">
              <p className="block w-70 ">Project Name:</p>

              <Input
                type="text"
                name="projectName"
                placeholder="Project Name"
                value={formData.projectName}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>

            <div className="flex items-center">
              <p className="block w-70 ">Scan Name:</p>

              <Input
                type="text"
                name="scanName"
                placeholder="Scan Name"
                value={formData.scanName}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>

            <div className="flex items-center">
              <p className="block w-70 ">Project Description:</p>

              <Textarea
                name="description"
                placeholder="Project Description"
                value={formData.description}
                onChange={handleInputChange}
                className="resize-none"
                //className="w-full p-2 border rounded"
              />
            </div>
          </div>
        );
      case 2:
        return (
          <div className="space-y-4">
            {renderError()}
            <h2 className="text-xl font-semibold">Target Details</h2>
            <div className="flex justify-start items-center gap-2">
              <p className="block w-70 ">Audit Method:</p>

              <Select
                value={formData.OS}
                onValueChange={(value) => handleInputChange(value, "OS")}
              >
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Select OS" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="windows">Windows</SelectItem>
                  <SelectItem value="linux">Linux</SelectItem>
                </SelectContent>
              </Select>

              <Select
                value={formData.auditMethod}
                onValueChange={(value) =>
                  handleInputChange(value, "auditMethod")
                }
              >
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Select Audit Method" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="agent">Agent</SelectItem>
                  <SelectItem value="remoteAccess">Remote Access</SelectItem>
                  <SelectItem value="uploadConfig">Upload Config</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {formData.auditMethod === "agent" && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <Button
                    type="button"
                    className="px-4 py-2 bg-black text-white rounded"
                    onClick={() => console.log("Download agent")}
                  >
                    Download Script
                  </Button>
                </div>
              </div>
            )}

            {formData.auditMethod === "remoteAccess" && (
              <div className="space-y-4">
                <div className="flex items-center">
                  <p className="block w-70">Target:</p>

                  <Input
                    type="text"
                    name="target"
                    placeholder="target"
                    value={formData.target}
                    onChange={handleInputChange}
                    className="w-80"
                    required
                    //className="w-full p-2 border rounded"
                  />

                  <Button className="ml-4" type="button">
                    Upload
                  </Button>
                </div>

                <div className="flex justify-start items-center">
                  <p className="block w-70 ">Authentication Method:</p>
                  <Select
                    value={formData.authMethod}
                    onValueChange={(value) =>
                      handleInputChange(value, "authMethod")
                    }
                  >
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Select Auth Method" />
                    </SelectTrigger>
                    {formData.OS === "windows" && (
                      <SelectContent>
                        <SelectItem value="password">Password</SelectItem>
                        <SelectItem value="ntlm">NTLM Hash</SelectItem>
                        <SelectItem value="lm">LM Hash</SelectItem>
                        <SelectItem value="kerberos">Kerberos</SelectItem>
                      </SelectContent>
                    )}
                    {formData.OS === "linux" && (
                      <SelectContent>
                        <SelectItem value="password">Password</SelectItem>
                        <SelectItem value="publicKey">Public Key</SelectItem>
                        <SelectItem value="certificate">Certificate</SelectItem>
                        <SelectItem value="kerberos">Kerberos</SelectItem>
                      </SelectContent>
                    )}
                  </Select>
                </div>

                {formData.authMethod === "password" && (
                  <div className="space-y-4">
                    <div className="flex items-center">
                      <p className="block w-70">Username:</p>
                      <Input
                        type="text"
                        name="username"
                        placeholder="Username"
                        value={formData.username}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70">Password:</p>
                      <Input
                        type="password"
                        name="password"
                        placeholder="Password"
                        value={formData.password}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70 ">Domain:</p>

                      <Input
                        type="text"
                        name="domain"
                        placeholder="Domain"
                        value={formData.domain}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    {formData.OS === "linux" && (
                      <ElevatePrivilegeForm
                        elevatePrivilege={formData.elevatePrivilege}
                        formData={formData}
                        handleInputChange={handleInputChange}
                      />
                    )}
                  </div>
                )}

                {formData.authMethod === "ntlm" &&
                  formData.OS === "windows" && (
                    <div className="space-y-4">
                      <div className="flex items-center">
                        <p className="block w-70">Username:</p>
                        <Input
                          type="text"
                          name="username"
                          placeholder="Username"
                          value={formData.username}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">NTLM Hash:</p>
                        <Input
                          type="text"
                          name="ntlmHash"
                          placeholder="NTLM Hash"
                          value={formData.ntlmHash}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Domain:</p>
                        <Input
                          type="text"
                          name="domain"
                          placeholder="Domain"
                          value={formData.domain}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                    </div>
                  )}
                {formData.authMethod === "kerberos" && (
                  <div className="space-y-4">
                    <div className="flex items-center">
                      <p className="block w-70">Username:</p>
                      <Input
                        type="text"
                        name="username"
                        placeholder="Username"
                        value={formData.username}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70">Password:</p>
                      <Input
                        type="password"
                        name="password"
                        placeholder="Password"
                        value={formData.password}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70">
                        Key Distribution Center (KDC):
                      </p>
                      <Input
                        type="text"
                        name="kdc"
                        placeholder="kdc.example.com"
                        value={formData.kdc}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70">KDC Transport: </p>
                      <Input
                        type="text"
                        name="kdcPort"
                        placeholder="KDC Port"
                        value={formData.kdcPort}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70">Domain:</p>
                      <Input
                        type="text"
                        name="domain"
                        placeholder="Domain"
                        value={formData.domain}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    {formData.OS === "linux" && (
                      <ElevatePrivilegeForm
                        elevatePrivilege={formData.elevatePrivilege}
                        formData={formData}
                        handleInputChange={handleInputChange}
                      />
                    )}
                  </div>
                )}

                {formData.authMethod === "publicKey" &&
                  formData.OS === "linux" && (
                    <div className="space-y-4">
                      <div className="flex items-center">
                        <p className="block w-70">Username:</p>
                        <Input
                          type="text"
                          name="username"
                          placeholder="Username"
                          value={formData.username}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Private Key</p>
                        <Button>Add file</Button>
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Private Key Passphrase</p>
                        <Input
                          type="text"
                          name="passphrase"
                          placeholder="Passphrase"
                          value={formData.privateKeyPassphrase}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <ElevatePrivilegeForm
                        elevatePrivilege={formData.elevatePrivilege}
                        formData={formData}
                        handleInputChange={handleInputChange}
                      />
                    </div>
                  )}

                {formData.authMethod === "certificate" &&
                  formData.OS === "linux" && (
                    <div className="space-y-4">
                      <div className="flex items-center">
                        <p className="block w-70">Username:</p>
                        <Input
                          type="text"
                          name="username"
                          placeholder="Username"
                          value={formData.username}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">User Certificate</p>
                        <Button>Add file</Button>
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Private Key</p>
                        <Button>Add file</Button>
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Private Key Passphrase</p>
                        <Input
                          type="text"
                          name="privateKeyPassphrase"
                          placeholder="Private Key Passphrase"
                          value={formData.privateKeyPassphrase}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <ElevatePrivilegeForm
                        elevatePrivilege={formData.elevatePrivilege}
                        formData={formData}
                        handleInputChange={handleInputChange}
                      />
                    </div>
                  )}

                {formData.authMethod === "lm" && formData.OS === "windows" && (
                  <div className="space-y-4 border-l-2 border-gray-200">
                    <div className="flex items-center">
                      <p className="block w-70">Username:</p>
                      <Input
                        type="text"
                        name="username"
                        placeholder="Username"
                        value={formData.username}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70">LM Hash:</p>
                      <Input
                        type="text"
                        name="lmHash"
                        placeholder="LM Hash"
                        value={formData.lmHash}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <div className="flex items-center">
                      <p className="block w-70">Domain:</p>
                      <Input
                        type="text"
                        name="domain"
                        placeholder="Domain"
                        value={formData.domain}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                  </div>
                )}
                <div className="space-y-4">
                  <h3 className="text-xl font-semibold">
                    Global Credentials Settings
                  </h3>
                  {formData.OS === "windows" && (
                    <>
                      <div className="flex items-center">
                        <Checkbox
                          className="mr-4"
                          checked={
                            formData.globalCredentials.neverSendCredentials ===
                            "true"
                          }
                          onCheckedChange={(checked) => {
                            handleNestedInputChange(
                              "globalCredentials",
                              "neverSendCredentials",
                              checked ? "true" : "false"
                            );
                          }}
                        />
                        <p>Never send credentials in the clear</p>
                      </div>
                      <div className="flex items-center">
                        <Checkbox
                          className="mr-4"
                          checked={
                            formData.globalCredentials.dontUseNTLMv1 === "true"
                          }
                          onCheckedChange={(checked) => {
                            handleNestedInputChange(
                              "globalCredentials",
                              "dontUseNTLMv1",
                              checked ? "true" : "false"
                            );
                          }}
                        />
                        <p>Do not use NTLMv1 authentication</p>
                      </div>
                      <div className="flex items-center">
                        <Checkbox
                          className="mr-4"
                          checked={
                            formData.globalCredentials
                              .startRemoteRegistryService === "true"
                          }
                          onCheckedChange={(checked) => {
                            handleNestedInputChange(
                              "globalCredentials",
                              "startRemoteRegistryService",
                              checked ? "true" : "false"
                            );
                          }}
                        />
                        <p>start the remote registry service during the scan</p>
                      </div>
                      <div className="flex items-center">
                        <Checkbox
                          className="mr-4"
                          checked={
                            formData.globalCredentials
                              .enableAdministrativeShares === "true"
                          }
                          onCheckedChange={(checked) => {
                            handleNestedInputChange(
                              "globalCredentials",
                              "enableAdministrativeShares",
                              checked ? "true" : "false"
                            );
                          }}
                        />
                        <p>Enable administrative shares during the scan</p>
                      </div>
                      <div className="flex items-center">
                        <Checkbox
                          className="mr-4"
                          checked={
                            formData.globalCredentials.startServerService ===
                            "true"
                          }
                          onCheckedChange={(checked) => {
                            handleNestedInputChange(
                              "globalCredentials",
                              "startServerService",
                              checked ? "true" : "false"
                            );
                          }}
                        />
                        <p>Start the Server Service during the scan</p>
                      </div>
                    </>
                  )}
                  {formData.OS === "linux" && (
                    <>
                      <div className="flex items-center">
                        <p className="block w-70">known_hosts file</p>
                        <Button>Add file</Button>
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Preferred port</p>
                        <Input
                          type="number"
                          name="preferredPort"
                          placeholder="port"
                          value={formData.port}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Client Version</p>
                        <Input
                          type="text"
                          name="clientVersion"
                          placeholder="Client Version"
                          value={formData.clientVersion}
                          onChange={handleInputChange}
                          className="w-80"
                          required
                        />
                      </div>
                      <div className="flex items-center">
                        <p className="block w-70">Attempt Least Privilege</p>
                        <Checkbox
                          checked={formData.attemptLeastPrivilege === "true"}
                          onCheckedChange={(checked) => {
                            handleInputChange(
                              checked ? "true" : "false",
                              "attemptLeastPrivelege"
                            );
                          }}
                        />
                      </div>
                    </>
                  )}
                </div>
              </div>
            )}

            {formData.auditMethod === "uploadConfig" && (
              <>
                <div className="space-y-4">
                  {renderError()}
                  <div className="flex justify-between items-center">
                    <Button
                      type="button"
                      className="px-4 py-2 bg-black text-white rounded"
                      onClick={() => console.log("Uploading config")}
                    >
                      Upload config
                    </Button>
                  </div>
                </div>
              </>
            )}
          </div>
        );
      case 3:
        //get all categories from complianceData
        const categories = [
          ...new Set(complianceData.map((item) => item.Categories)),
        ];

        //get all standards filtered by category
        const standards = complianceData
          .filter((item) => item.Categories === formData.complianceCategory)
          .map((item) => item["Security Standards"]);

        return (
          <div className="space-y-4">
            {renderError()}
            <h2 className="text-xl font-semibold">Compliance Information</h2>

            {/* Operating System Selection */}
            <div className="flex items-center">
              <p className="block w-70">Network Solution:</p>
              <Select
                value={formData.complianceCategory}
                onValueChange={(value) =>
                  handleInputChange(value, "complianceCategory")
                }
              >
                <SelectTrigger className="w-80">
                  <SelectValue placeholder="Select Network Solution" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map((category) => (
                    <SelectItem key={category} value={category}>
                      {category}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            {/* Security Standard Selection */}
            <div className="flex items-center">
              <p className="block w-70">Security Standard:</p>
              <Select
                value={formData.complianceSecurityStandard}
                onValueChange={(value) =>
                  handleInputChange(value, "complianceSecurityStandard")
                }
              >
                <SelectTrigger className="w-80">
                  <SelectValue placeholder="Select Security Standard" />
                </SelectTrigger>
                <SelectContent>
                  {standards.map((standard) => (
                    <SelectItem key={standard} value={standard}>
                      {standard}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        );
      case 4:
        return (
          <div className="space-y-6">
            {renderError()}
            <h2 className="text-xl font-semibold">Scan Settings</h2>

            {/* Schedule Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <p className="font-medium">Schedule Scan</p>
                  <p className="text-sm text-gray-500">
                    Enable to schedule recurring scans
                  </p>
                </div>
                <Switch
                  checked={formData.schedule === "true"}
                  onCheckedChange={(checked) =>
                    handleInputChange(checked.toString(), "schedule")
                  }
                />
              </div>

              {formData.schedule === "true" && (
                <div className="space-y-4 pl-4 border-l-2 border-gray-200">
                  <div className="flex items-center">
                    <p className="block w-70">Frequency:</p>
                    <Select
                      value={formData.scheduleFrequency}
                      onValueChange={(value) =>
                        handleInputChange(value, "scheduleFrequency")
                      }
                    >
                      <SelectTrigger className="w-80">
                        <SelectValue placeholder="Select frequency" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="daily">Daily</SelectItem>
                        <SelectItem value="weekly">Weekly</SelectItem>
                        <SelectItem value="monthly">Monthly</SelectItem>
                        <SelectItem value="yearly">Yearly</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="flex items-center">
                    <p className="block w-70">Start Date:</p>
                    <Input
                      type="date"
                      name="scheduleStartDate"
                      value={formData.scheduleStartDate}
                      onChange={handleInputChange}
                      className="w-80"
                      required
                    />
                  </div>

                  <div className="flex items-center">
                    <p className="block w-70">Start Time:</p>
                    <Input
                      type="time"
                      name="scheduleStartTime"
                      value={formData.scheduleStartTime}
                      onChange={handleInputChange}
                      className="w-80"
                      required
                    />
                  </div>
                  <div className="flex items-center">
                    <p className="block w-70">Timezone:</p>
                    <Select
                      value={formData.scheduleTimezone}
                      onValueChange={(value) =>
                        handleInputChange(value, "scheduleTimezone")
                      }
                    >
                      <SelectTrigger className="w-80">
                        <SelectValue placeholder="Select timezone" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="IST">IST</SelectItem>
                        <SelectItem value="UTC">UTC</SelectItem>
                        <SelectItem value="EST">EST</SelectItem>
                        <SelectItem value="PST">PST</SelectItem>
                        {/* Add more timezones as needed */}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              )}
            </div>

            {/* Notification Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <p className="font-medium">Email Notifications</p>
                  <p className="text-sm text-gray-500">
                    Get notified about scan results
                  </p>
                </div>
                <Switch
                  checked={formData.notification === "true"}
                  onCheckedChange={(checked) =>
                    handleInputChange(checked.toString(), "notification")
                  }
                />
              </div>

              {formData.notification === "true" && (
                <div className="space-y-4 pl-4 border-l-2 border-gray-200">
                  <div className="flex items-center">
                    <p className="block w-70">Email Address:</p>
                    <Input
                      type="email"
                      name="notificationEmail"
                      placeholder="Enter email address"
                      value={formData.notificationEmail}
                      onChange={handleInputChange}
                      className="w-80"
                      required
                    />
                  </div>
                </div>
              )}
            </div>
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={true} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64 pt-20">
        <Header title="Firewall Configuration Audit Scan" />

        <Card className="w-[85%] mt-4 ml-4">
          <CardContent className="w-full p-4 pl-12">
            <div className="w-[80%] space-y-6">
              <form onSubmit={handleSubmit}>
                {renderPage()}

                <div className="flex justify-between mt-6">
                  <button
                    type="button"
                    onClick={prevPage}
                    className={`px-4 py-2 rounded ${
                      page === 1 ? "bg-gray-300" : "bg-black text-white"
                    }`}
                    disabled={page === 1}
                  >
                    Previous
                  </button>
                  <Breadcrumbs currentPage={page} pages={formPages} />
                  {page === 4 ? (
                    <button
                      type="button"
                      onClick={handleSubmit}
                      className="px-4 py-2 bg-green-500 text-white rounded"
                    >
                      Submit
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={nextPage}
                      className="px-4 py-2 bg-black text-white rounded"
                    >
                      Next
                    </button>
                  )}
                </div>
              </form>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default ScanCAFirewall;
