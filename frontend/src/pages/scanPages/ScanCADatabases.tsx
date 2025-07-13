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
import { Label } from "@/components/ui/label";
import { useNavigate } from "react-router-dom";
import Papa from 'papaparse';
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import FileUploader from "@/components/FileUploader";
import { toast, Toaster } from "sonner";
import { CheckCircle2 } from "lucide-react";

import api from "../api";

const ScanCADatabases = () => {
  const navigate = useNavigate();
  const [complianceData, setComplianceData] = useState([]);
  const [errors, setErrors] = useState("");
  const [fileIPs, setFileIPs] = useState<string[]>([]);

  const formPages = ["●", "●", "●", "●", "●"];

  const formPagesAgent = ["●", "●", "●", "●"];

  const [page, setPage] = useState(1);
  const [userName, setUserName] = useState("");
  const [selectedComplianceItems, setSelectedComplianceItems] = useState<
    string[]
  >([]);
  const [uncheckedComplianceItems, setUncheckedComplianceItems] = useState<
    string[]
  >([]);

  const [formData, setFormData] = useState({
    // General Info
    scanName: "",
    projectName: "",
    description: "",

    // Target Details
    auditMethod: "",
    OS: "",
    target: "",
    targetList: [],
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
     selectedFlavour: "",
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
    auditNames: [],
  });

  const validatePage1 = () => {
    return (
      formData.scanName.trim() !== "" && formData.projectName.trim() !== ""
    );
  };

  const isValidIPv4 = (ip: string) => {
    const ipv4Regex =
      /^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$/;
    return ipv4Regex.test(ip);
  };

  const isValidCIDR = (input: string) => {
    const cidrRegex =
      /^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\/([0-9]|[1-2][0-9]|3[0-2])$/;
    return cidrRegex.test(input);
  };

  const isValidRange = (input: string) => {
    const rangeRegex =
      /^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(\d{1,3})-(\d{1,3})$/;
    const match = input.match(rangeRegex);
    if (!match) return false;

    const base = input.substring(0, input.lastIndexOf(".")) + "."; // e.g. "192.168.1."
    const start = parseInt(match[3], 10); // start of range (last octet)
    const end = parseInt(match[4], 10); // end of range (last octet)

    // Check range validity
    if (isNaN(start) || isNaN(end)) return false;
    if (start > end) return false;
    if (start < 0 || start > 255) return false;
    if (end < 0 || end > 255) return false;

    // Validate full IPs constructed from base + start/end
    return isValidIPv4(base + start) && isValidIPv4(base + end);
  };

  const isValidHostname = (input: string) => {
    const hostnameRegex = /^(?!:\/\/)([a-zA-Z0-9-_]+\.)+[a-zA-Z]{2,}$/;
    return hostnameRegex.test(input);
  };

  const validateTargetIPInput = (input: string) => {
    const targets = input
      .split(/[ ,]+/)
      .map((t) => t.trim())
      .filter(Boolean);

    return targets.every(
      (target) =>
        isValidIPv4(target) ||
        isValidCIDR(target) ||
        isValidRange(target) ||
        isValidHostname(target)
    );
  };

  const validatePage2 = () => {
    if (!formData.auditMethod) return "Audit method is required.";


    if (formData.auditMethod === "remoteAccess") {
      if (!formData.target) return "Target IP is required.";
      if (!validateTargetIPInput(formData.target))
        return "Invalid IP address format.";
      if (!formData.authMethod) return "Authentication method is required.";

      switch (formData.authMethod) {
        case "password":
          if (!formData.username || !formData.password) {
            return "Username and password are required.";
          }
          break;
        case "ntlm":
          if (!formData.username || !formData.ntlmHash || !formData.domain) {
            return "Username, NTLM hash, and domain are required.";
          }
          break;
        case "kerberos":
          if (
            !formData.username ||
            !formData.password ||
            !formData.kdc ||
            !formData.kdcPort ||
            !formData.domain
          ) {
            return "All Kerberos fields are required.";
          }
          break;
        case "lm":
          if (!formData.username || !formData.lmHash || !formData.domain) {
            return "Username, LM hash, and domain are required.";
          }
          break;
        case "publicKey":
        case "certificate":
          if (!formData.username || !formData.privateKeyPassphrase) {
            return "Username and private key passphrase are required.";
          }
          break;
        default:
          return "Unsupported authentication method.";
      }
    }

    return true; // Valid for agent and uploadConfig
  };

  const validatePage4 = () => {
    return (
      formData.complianceCategory !== "" &&
      formData.complianceSecurityStandard !== ""
    );
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response1 = await api.get("users/userinfo");
        setUserName(response1.data.username);
        const response = await api.get(
          "/scans/compliance/configaudit/database/"
        );
        console.log("Fetched data:", response.data);
        setComplianceData(response.data);
        console.log(response.data);
      } catch (error) {
        console.error("Error fetching compliance data:", error);
        setErrors("Error fetching compliance data. Please try again later.");
      }
    };

    fetchData();
  }, []);

  async function loadAuditNames(flavour, securityStandard, complianceCategory) {
  const filename = `${complianceCategory}_${securityStandard}`
    .toLowerCase()
    .replace(/\s+/g, "_");

  const folderPath = `Configuration_Audit/Database/${flavour}/${securityStandard}/Queries`;

  try {
    const response = await api.get(`/get-csv/${folderPath}/${filename}/`, {
      responseType: 'text',
    });

    const csvText = response.data;

    // Parse with PapaParse
    const result = Papa.parse(csvText, {
      header: true,
      skipEmptyLines: true,
    });

    const auditData = result.data.map((row) => ({
      name: row.name?.trim(),
      check: row.check?.trim().toLowerCase() === 'true',
    }));

    handleInputChange(auditData, "auditNames");

    const initiallyChecked = auditData
      .filter(item => item.check)
      .map(item => item.name);

    setSelectedComplianceItems(initiallyChecked);
  } catch (error) {
    console.error("Error fetching compliance data:", error);
  }
}






  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | any,
    field?: string
  ) => {
    if (field) {
      setFormData((prev) => ({
        ...prev,
        [field]: e, // ✅ Handles strings, arrays, objects, etc.
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

  const handleFileParsed = (parsedIps: string[]) => {
    setFileIPs(parsedIps);
    setFormData((prev) => ({
      ...prev,
      targetList: parsedIps,
    }));
  };

  const nextPage = () => {
    let validationResult = false;

    switch (page) {
      case 1:
        validationResult = validatePage1();
        break;
      case 2:
        validationResult = validatePage2();
        break;
      case 3:
        validationResult = true;
        break;
      case 4:
        validationResult = validatePage4();
        break;
      case 5:
        validationResult = true;
        break;
      default:
        validationResult = false;
    }

    if (validationResult !== true) {
      setErrors(
        validationResult ||
          "Please fill in all required fields before proceeding."
      );
      return;
    }

    setErrors(""); // Clear any existing errors
    if (page < 5) setPage((prev) => prev + 1);
  };

  const prevPage = () => {
    if (page > 1) setPage((prev) => prev - 1);
  };

  const downloadScript = async () => {
    if (!formData.auditMethod) {
        setErrors("Please select a network solution (audit method) before downloading the script.");
        return;
    }

    if (!formData.complianceSecurityStandard) {
        setErrors("Please select a security standard before downloading the script.");
        return;
    }
    setErrors("");
    const scanPayload = {
      project_name: formData.projectName,
      scan_name: formData.scanName,
      scan_author: userName || "unknown",
      scan_status: "Pending",
      scan_type:"Configuration Audit",

      scan_data: {
        scanType: "Configuration Audit",
        description: formData.description,
        category: "database",
        os: formData.OS,
        auditMethod: formData.auditMethod,
        target: formData.target,
        elevatePrivilege: formData.elevatePrivilege,
        authMethod: formData.authMethod,
        username: formData.username,
        password: formData.password,
        domain: formData.domain,
        ntlmHash: formData.ntlmHash,
        lmHash: formData.lmHash,
        kdc: formData.kdc,
        kdcPort: formData.kdcPort,
        kdcTransport: formData.kdcTransport,
        certificate: formData.certificate,
        publicKey: formData.publicKey,
        privateKeyPassphrase: formData.privateKeyPassphrase,
        port: formData.port,
        clientVersion: formData.clientVersion,
        attemptLeastPrivilege: formData.attemptLeastPrivilege,

        EP_escalationAccount: formData.EP_escalationAccount,
        EP_escalationPassword: formData.EP_escalationPassword,
        EP_dzdoDirectory: formData.EP_dzdoDirectory,
        EP_suDirectory: formData.EP_suDirectory,
        EP_pbrunDirectory: formData.EP_pbrunDirectory,
        EP_su_sudoDirectory: formData.EP_su_sudoDirectory,
        EP_su_login: formData.EP_su_login,
        EP_su_user: formData.EP_su_user,
        EP_sudoUser: formData.EP_sudoUser,
        EPsshUserPassword: formData.EPsshUserPassword,
        EPenablePassword: formData.EPenablePassword,

        globalCredentials: {
          neverSendCredentials: formData.globalCredentials.neverSendCredentials,
          dontUseNTLMv1: formData.globalCredentials.dontUseNTLMv1,
          startRemoteRegistryService:
            formData.globalCredentials.startRemoteRegistryService,
          enableAdministrativeShares:
            formData.globalCredentials.enableAdministrativeShares,
          startServerService: formData.globalCredentials.startServerService,
        },

        complianceCategory: formData.complianceCategory,
        complianceSecurityStandard: formData.complianceSecurityStandard,

        schedule: formData.schedule,
        scheduleFrequency: formData.scheduleFrequency,
        scheduleStartDate: formData.scheduleStartDate,
        scheduleStartTime: formData.scheduleStartTime,
        scheduleTimezone: formData.scheduleTimezone,
        notification: formData.notification,
        notificationEmail: formData.notificationEmail,
        uncheckedComplianceItems: uncheckedComplianceItems,
      },
    };

    try {
      const response = await api.post("/scans/create-scan/", scanPayload, {
        responseType: "blob",
      });

      const contentDisposition = response.headers["content-disposition"];
      let filename = "script.sql";

      if (contentDisposition) {
        const match = contentDisposition.match(/filename="?(.+)"?/);
        if (match?.[1]) filename = match[1];
      }

      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", filename);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error(
        "Error downloading script:",
        error.response?.data || error.message
      );
      alert("Failed to download the script.");
    }
  };

  const handleSubmit = async () => {
    try {
      const toastId = toast.info("Processing scan ...", { duration: Infinity });
      const response = await api.post("/scans/create-scan/", {
        project_name: formData.projectName,
        scan_name: formData.scanName,
        scan_author: userName, // Replace with actual user context if needed
        scan_status: "Pending",
        scan_type:"Configuration Audit",

        scan_data: {
          scanType: "Configuration Audit",
          description: formData.description,
          category: "database",
          os: formData.OS,
          auditMethod: formData.auditMethod,
          target: formData.target,
          elevatePrivilege: formData.elevatePrivilege,
          authMethod: formData.authMethod,
          username: formData.username,
          password: formData.password,
          domain: formData.domain,
          ntlmHash: formData.ntlmHash,
          lmHash: formData.lmHash,
          kdc: formData.kdc,
          kdcPort: formData.kdcPort,
          kdcTransport: formData.kdcTransport,
          certificate: formData.certificate,
          publicKey: formData.publicKey,
          privateKeyPassphrase: formData.privateKeyPassphrase,
          port: formData.port,
          clientVersion: formData.clientVersion,
          attemptLeastPrivilege: formData.attemptLeastPrivilege,

          EP_escalationAccount: formData.EP_escalationAccount,
          EP_escalationPassword: formData.EP_escalationPassword,
          EP_dzdoDirectory: formData.EP_dzdoDirectory,
          EP_suDirectory: formData.EP_suDirectory,
          EP_pbrunDirectory: formData.EP_pbrunDirectory,
          EP_su_sudoDirectory: formData.EP_su_sudoDirectory,
          EP_su_login: formData.EP_su_login,
          EP_su_user: formData.EP_su_user,
          EP_sudoUser: formData.EP_sudoUser,
          EPsshUserPassword: formData.EPsshUserPassword,
          EPenablePassword: formData.EPenablePassword,

          globalCredentials: {
            neverSendCredentials:
              formData.globalCredentials.neverSendCredentials,
            dontUseNTLMv1: formData.globalCredentials.dontUseNTLMv1,
            startRemoteRegistryService:
              formData.globalCredentials.startRemoteRegistryService,
            enableAdministrativeShares:
              formData.globalCredentials.enableAdministrativeShares,
            startServerService: formData.globalCredentials.startServerService,
          },

          complianceCategory: formData.complianceCategory,
          complianceSecurityStandard: formData.complianceSecurityStandard,

          schedule: formData.schedule,
          scheduleFrequency: formData.scheduleFrequency,
          scheduleStartDate: formData.scheduleStartDate,
          scheduleStartTime: formData.scheduleStartTime,
          scheduleTimezone: formData.scheduleTimezone,
          notification: formData.notification,
          notificationEmail: formData.notificationEmail,
          uncheckedComplianceItems: uncheckedComplianceItems,
        },
      });
      toast.dismiss(toastId); // hide the processing toast
      console.log("Scan created successfully:", response.data);
      toast.success("Scan created succesfully", {
        icon: <CheckCircle2 className="text-green-500" />,
      });
      setTimeout(() => {
         navigate(`/scan/scanresult/${formData.projectName}/${formData.scanName}`);
      }, 2000);

      // Optionally reset form here
      // setFormData(initialFormData);
    } catch (error) {
      console.error(
        "Error creating scan:",
        error.response?.data || error.message
      );
      alert("Failed to create scan.");
    }
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
                className="resize-none w-80"
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
        <p className="block w-68">Audit Method:</p>

        <Select
          value={formData.auditMethod}
          onValueChange={(value) => handleInputChange(value, "auditMethod")}
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
            />
            <FileUploader onFileParsed={handleFileParsed} />
          </div>

          <div className="flex justify-start items-center">
            <p className="block w-70">Authentication Method:</p>
            <Select
              value={formData.authMethod}
              onValueChange={(value) =>
                handleInputChange(value, "authMethod")
              }
            >
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Select Auth Method" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="password">Password</SelectItem>
                <SelectItem value="publicKey">Public Key</SelectItem>
                <SelectItem value="certificate">Certificate</SelectItem>
                <SelectItem value="kerberos">Kerberos</SelectItem>
              </SelectContent>
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

              <ElevatePrivilegeForm
                elevatePrivilege={formData.elevatePrivilege}
                formData={formData}
                handleInputChange={handleInputChange}
              />
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
                <p className="block w-70">Key Distribution Center (KDC):</p>
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
                <p className="block w-70">KDC Transport:</p>
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

              <ElevatePrivilegeForm
                elevatePrivilege={formData.elevatePrivilege}
                formData={formData}
                handleInputChange={handleInputChange}
              />
            </div>
          )}

          {formData.authMethod === "publicKey" && (
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
                  name="privateKeyPassphrase"
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

          {formData.authMethod === "certificate" && (
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
        </div>
      )}

      {formData.auditMethod === "uploadConfig" && (
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
      )}
    </div>
  );

      case 3:
        return (
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
                      formData.globalCredentials.neverSendCredentials === "true"
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
                      formData.globalCredentials.startRemoteRegistryService ===
                      "true"
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
                      formData.globalCredentials.enableAdministrativeShares ===
                      "true"
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
                      formData.globalCredentials.startServerService === "true"
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
                    name="port"
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
        );
      case 4: {
  // Get unique flavours from complianceData
  const flavours = [
    ...new Set(complianceData.map((item) => item.Flavours)),
  ];

  // Get categories based on selected flavour
  const categories = [
    ...new Set(
      complianceData
        .filter((item) => item.Flavours === formData.selectedFlavour)
        .map((item) => item.Categories)
    ),
  ];

  // Get standards based on selected category
  const standards = [
    ...new Set(
      complianceData
        .filter((item) => item.Categories === formData.complianceCategory)
        .map((item) => item["Security Standards"])
    ),
  ];

  return (
    <div className="flex gap-6">
      {/* Left 70%: Non-scrollable form content */}
      <div className="w-[70%] space-y-4">
        {renderError()}
        <h2 className="text-xl font-semibold">Compliance Information</h2>

        {/* Flavour Selection */}
        <div className="flex items-center">
          <p className="block w-70">Select DB:</p>
          <Select
            value={formData.selectedFlavour}
            onValueChange={(value) => {
              handleInputChange(value, "selectedFlavour");

              // Reset dependent selections
              setFormData((prev) => ({
                ...prev,
                complianceCategory: "",
                complianceSecurityStandard: "",
                auditNames: [],
              }));
              setSelectedComplianceItems([]);
              setUncheckedComplianceItems([]);
            }}
          >
            <SelectTrigger className="w-80">
              <SelectValue placeholder="Select Flavour" />
            </SelectTrigger>
            <SelectContent>
              {flavours.map((item) => (
                <SelectItem key={item} value={item}>
                  {item}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Compliance Category Selection */}
        <div className="flex items-center">
          <p className="block w-70">Compliance Category:</p>
          <Select
            value={formData.complianceCategory}
            onValueChange={(value) => {
              handleInputChange(value, "complianceCategory");

              // Reset security standard and audit names
              setFormData((prev) => ({
                ...prev,
                complianceSecurityStandard: "",
                auditNames: [],
              }));
              setSelectedComplianceItems([]);
              setUncheckedComplianceItems([]);

              // Load audit names if all required values are selected
              if (formData.selectedFlavour && formData.complianceSecurityStandard && value) {
                loadAuditNames(
                  formData.selectedFlavour,
                  formData.complianceSecurityStandard,
                  value
                );
              }
            }}
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
            onValueChange={(value) => {
              handleInputChange(value, "complianceSecurityStandard");

              // Load audit names if all required values are selected
              if (formData.selectedFlavour && value && formData.complianceCategory) {
                loadAuditNames(
                  formData.selectedFlavour,
                  value,
                  formData.complianceCategory
                );
              }
            }}
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

      {/* Right 30%: Scrollable content with fixed height */}
      <div className="w-[30%] flex flex-col">
        <div className="max-h-96 overflow-y-auto border-l pl-4 pr-2 space-y-3">
          {formData.auditNames.length > 0 ? (
            formData.auditNames.map((item, index) => (
              <div key={index} className="flex items-center space-x-2">
                <Checkbox
                  id={`compliance-${index}`}
                  checked={selectedComplianceItems.includes(item.name)}
                  onCheckedChange={(checked) => {
                    setSelectedComplianceItems((prev) =>
                      checked
                        ? [...prev, item.name]
                        : prev.filter((v) => v !== item.name)
                    );

                    setUncheckedComplianceItems((prev) =>
                      !checked
                        ? [...prev, item.name]
                        : prev.filter((v) => v !== item.name)
                    );
                  }}
                />
                <Label
                  htmlFor={`compliance-${index}`}
                  className="text-sm"
                >
                  {item.name}
                </Label>
              </div>
            ))
          ) : (
            <p className="text-gray-500">No compliance data available.</p>
          )}
        </div>
      </div>
    </div>
  );
}


      case 5:
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
  const dummyItems = Array.from(
    { length: 30 },
    (_, i) => `Test item #${i + 1}`
  );

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={true} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64 pt-20">
        <Header title="Databases Configuration Audit Scan" />

        <Card className=" w-[85%] mt-10 ml-4 shadow-2xl">
          <CardContent className="w-full p-4 px-12">
            <div className="w-auto space-y-6">
              <form onSubmit={handleSubmit}>
                {renderPage()}

                <div className="flex justify-between mt-6">
                  <button
                    type="button"
                    onClick={prevPage}
                    className={`px-4 py-2 rounded cursor-pointer ${
                      page === 1 ? "bg-gray-300" : "bg-black text-white"
                    }`}
                    disabled={page === 1}
                  >
                    Previous
                  </button>
                  <Breadcrumbs
                    currentPage={page}
                    pages={
                      formData.auditMethod === "agent"
                        ? formPagesAgent
                        : formPages
                    }
                  />
                  {page === 5 ? (
                    <button
                      type="button"
                      onClick={handleSubmit}
                      className="px-4 py-2 bg-green-500 w-25 text-white rounded cursor-pointer"
                    >
                      Submit
                    </button>
                  ) : formData.auditMethod === "agent" && page === 4 ? (
                    <Button
                      type="button"
                      className="px-4 py-2 bg-black text-white h-10 rounded cursor-pointer"
                      onClick={downloadScript} // no args, uses formData from closure
                    >
                      Download script
                    </Button>
                  ) : (
                    <button
                      type="button"
                      onClick={nextPage}
                      className="px-4 py-2 bg-black w-25 text-white rounded cursor-pointer"
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

export default ScanCADatabases;
