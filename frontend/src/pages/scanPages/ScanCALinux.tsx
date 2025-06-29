import Sidebar from "@/components/Sidebar";
import axios from "axios";
import Header from "@/components/Header";
import Breadcrumbs from "@/components/ui/Breadcrumbs";
import { ElevatePrivilegeForm } from "@/components/ElevatePrivilegeForm";
import { Card, CardContent } from "@/components/ui/card";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast, Toaster } from "sonner";
import { CheckCircle2 } from "lucide-react";
import FileUploader from "@/components/FileUploader";
import { useNavigate } from "react-router-dom";
import api from "../api";
import { Checkbox } from "@/components/ui/checkbox";

const ScanCALinux = () => {
  const [complianceData, setComplianceData] = useState([]);
  const [errors, setErrors] = useState("");
  const [userName, setUserName] = useState("");
  const [fileIPs, setFileIPs] = useState<string[]>([]);
  const navigate = useNavigate();

  const formPages = ["●", "●", "●", "●", "●"];

  const formPagesAgent = ["●", "●", "●", "●"];

  const [page, setPage] = useState(1);
  const [formData, setFormData] = useState({
    // General Info
    scanName: "",
    projectName: "",
    description: "",
    os: "Linux", // Default to Linux for this scan type
    scanType: "Configuration Audit",
    // Target Details
    auditMethod: "",
    target: "",
    targetList: "",
    authMethod: "",
    elevatePrivilege: "", //can be .k5login, Cisco enable, dzdo, su, pbrun, su+sudo, nothing
    username: "",
    password: "",
    domain: "",
    kdc: "",
    kdcPort: "",
    kdcTransport: "",
    certificate: "",
    publicKey: "",
    port: "",
    clientVersion: "",
    attemptLeastPrivelege: "",
    privateKeyPassphrase: "",

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
      formData.scanName.trim() !== "" && formData.projectName.trim() !== ""
    );
  };

  const isValidIPv4 = (ip: string) => {
    const ipv4Regex =
      /^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$/;
    return ipv4Regex.test(ip);
  };

  const isValidPort = (port: string) => {
    const p = parseInt(port as string, 10)
    return Number.isInteger(p) && p > 0 && p <= 65535;
  }

  const isValidHostname = (input: string) => {
    const hostnameRegex = /^(?!:\/\/)([a-zA-Z0-9-_]+\.)+[a-zA-Z]{2,}$/;
    return hostnameRegex.test(input);
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

  const isValidTargetWithPort = (input: string) => {
    if (input.includes("/")) {
    const [ip, port] = input.split("/");
      return (
        (isValidIPv4(ip) || isValidHostname(ip)) &&
        isValidPort(port)
      );
    }
    return (
    isValidIPv4(input) ||
    isValidCIDR(input) ||
    isValidRange(input) ||
    isValidHostname(input)
  );
 }

  const validateTargetIPInput = (input: string) => {
    const targets = input
      .split(/[ ,]+/)
      .map((t) => t.trim())
      .filter(Boolean);

    return targets.every((target) => isValidTargetWithPort(target));
  };

  const validatePage2 = () => {
    if (!formData.auditMethod) return "Audit method is required.";

    if (formData.auditMethod === "remote") {
      if (!formData.target) return "Target IP is required.";
      if (!validateTargetIPInput(formData.target))
        return "IP Address incorrect";
      if (!formData.authMethod) return "Authentication method is required.";

      // Validate based on authentication method
      switch (formData.authMethod) {
        case "password":
          if (!formData.username || !formData.password)
            return "Username and password are required.";
          break;
        case "publicKey":
        case "certificate":
          if (!formData.username || !formData.privateKeyPassphrase) {
            return "Username and private key passphrase are required.";
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
        default:
          return "Unsupported authentication method.";
      }

      // Validate elevation privilege fields if selected
      if (formData.elevatePrivilege) {
        switch (formData.elevatePrivilege) {
          case ".k5login":
            if (!formData.EP_escalationAccount)
              return "Escalation account is required for .k5login.";
            break;
          case "ciscoEnable":
            if (!formData.EPenablePassword)
              return "Enable password is required for Cisco.";
            break;
          case "dzdo":
            if (
              !formData.EP_escalationAccount ||
              !formData.EP_escalationPassword ||
              !formData.EP_dzdoDirectory
            ) {
              return "All dzdo fields are required.";
            }
            break;
          case "su":
            if (
              !formData.EP_suDirectory ||
              !formData.EP_su_login ||
              !formData.EP_escalationPassword
            ) {
              return "All su fields are required.";
            }
            break;
          case "pbrun":
            if (!formData.EP_pbrunDirectory || !formData.EPsshUserPassword) {
              return "All pbrun fields are required.";
            }
            break;
          case "su+sudo":
            if (
              !formData.EP_su_sudoDirectory ||
              !formData.EP_su_user ||
              !formData.EP_sudoUser ||
              !formData.EP_escalationPassword
            ) {
              return "All su+sudo fields are required.";
            }
            break;
          case "nothing":
            return true;
          default:
            return "Unsupported privilege elevation method.";
        }
      }
    }

    return true; // Passed validation
  };

  const validatePage4 = () => {
    return (
      formData.complianceCategory !== "" &&
      formData.complianceSecurityStandard !== ""
    );
  };

  const downloadScript = async () => {
    console.log("Downloading script with formData:", formData);
    const scanPayload = {
      project_name: formData.projectName,
      scan_name: formData.scanName,
      scan_author: userName || "unknown",
      scan_status: "Pending",

      scan_data: {
        scanType: "Configuration Audit",
        description: formData.description,
        category: "linux",
        os: formData.os,
        auditMethod: formData.auditMethod,
        target: formData.target,
        elevatePrivilege: formData.elevatePrivilege,
        authMethod: formData.authMethod,
        username: formData.username,
        password: formData.password,
        domain: formData.domain,
        kdc: formData.kdc,
        kdcPort: formData.kdcPort,
        kdcTransport: formData.kdcTransport,
        certificate: formData.certificate,
        publicKey: formData.publicKey,
        privateKeyPassphrase: formData.privateKeyPassphrase,
        port: formData.port,
        clientVersion: formData.clientVersion,
        attemptLeastPrivelege: formData.attemptLeastPrivelege,

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

        complianceCategory: formData.complianceCategory,
        complianceSecurityStandard: formData.complianceSecurityStandard,

        schedule: formData.schedule,
        scheduleFrequency: formData.scheduleFrequency,
        scheduleStartDate: formData.scheduleStartDate,
        scheduleStartTime: formData.scheduleStartTime,
        scheduleTimezone: formData.scheduleTimezone,
        notification: formData.notification,
        notificationEmail: formData.notificationEmail,
      },
    };

    console.log("Scan payload:", scanPayload);

    try {
      const response = await axios.post(
        "http://localhost:8000/api/scans/create-scan/",
        scanPayload,
        {
          responseType: "blob",
          timeout: 60000,
        }
      );

      const contentDisposition = response.headers["content-disposition"];
      let filename = "script.sh";

      if (contentDisposition) {
        const match = contentDisposition.match(/filename="?([^"]+)"?/);
        if (match?.[1]) {
          filename = match[1];
        }
      }
      console.log("Downloading script:", filename);
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", filename);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error("Error downloading script:", error);
      alert("Failed to download the script.");
    }
  };
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response1 = await api.get("users/userinfo");
        setUserName(response1.data.username);

        const response = await api.get("/scans/compliance/configaudit/linux/"); // Adjust the endpoint as needed
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

  const handleSubmit = async () => {
    try {
      const toastId = toast.info("Processing scan ...", { duration: Infinity });
      const payload = {
        project_name: formData.projectName,
        scan_name: formData.scanName,
        scan_author: userName, // Replace with user context if needed
        scan_status: "Pending",
        scan_data: {
          scanType: "Configuration Audit",
          description: formData.description,
          category: "linux",

          // Target Details
          auditMethod: formData.auditMethod,
          target: formData.target,
          authMethod: formData.authMethod,
          elevatePrivilege: formData.elevatePrivilege,
          username: formData.username,
          password: formData.password,
          domain: formData.domain,
          kdc: formData.kdc,
          kdcPort: formData.kdcPort,
          kdcTransport: formData.kdcTransport,
          certificate: formData.certificate,
          publicKey: formData.publicKey,
          port: formData.port,
          clientVersion: formData.clientVersion,
          privateKeyPassphrase: formData.privateKeyPassphrase,

          // Elevation Params
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

          // Compliance Info
          complianceCategory: formData.complianceCategory,
          complianceSecurityStandard: formData.complianceSecurityStandard,

          // Scan Schedule
          schedule: formData.schedule,
          scheduleFrequency: formData.scheduleFrequency,
          scheduleStartDate: formData.scheduleStartDate,
          scheduleStartTime: formData.scheduleStartTime,
          scheduleTimezone: formData.scheduleTimezone,
          notification: formData.notification,
          notificationEmail: formData.notificationEmail,
        },
      };

      const response = await api.post("scans/create-scan/", payload); // Ensure "test/" maps to your backend view
      toast.dismiss(toastId); // hide the processing toast
      console.log("Scan created:", response.data);
      toast.success("Scan created succesfully", {
        icon: <CheckCircle2 className="text-green-500" />,
      });
      setTimeout(() => {
        navigate(`/scan/scanresult/${formData.projectName}/${formData.scanName}`);
      }, 2000);
      // Optionally reset form
      // setFormData(initialState);
    } catch (error) {
      console.error("Error creating scan:", error);
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
                className="w-80"
                onChange={handleInputChange}
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
            <div className="flex justify-start items-center">
              <p className="block w-70 ">Audit Method:</p>

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
                  <SelectItem value="remote">Remote Access</SelectItem>
                  <SelectItem value="uploadConfig">Upload Config</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {formData.auditMethod === "remote" && (
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

                  <FileUploader onFileParsed={handleFileParsed}></FileUploader>
                </div>

                <div className="flex justify-start items-center mb-4">
                  <p className="block w-70 ">Authentication Method (SSH)</p>
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
              <>
                <div className="space-y-4">
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
        return (
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">
              Global Credential Settings
            </h2>
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
                checked={formData.attemptLeastPrivelege === "true"}
                onCheckedChange={(checked) => {
                  handleInputChange(
                    checked ? "true" : "false",
                    "attemptLeastPrivelege"
                  );
                }}
              />
            </div>
          </div>
        );
      case 4: {
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
              <p className="block w-70">Operating System:</p>
              <Select
                value={formData.complianceCategory}
                onValueChange={(value) =>
                  handleInputChange(value, "complianceCategory")
                }
              >
                <SelectTrigger className="w-80">
                  <SelectValue placeholder="Select Linux Distro" />
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

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={true} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64 pt-20">
        <Header title="Linux Configuration Audit Scan" />

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
                      className="px-4 py-2 w-25 bg-green-500 text-white rounded cursor-pointer"
                    >
                      Submit
                    </button>
                  ) : formData.auditMethod === "agent" && page === 4 ? (
                    <Button
                      type="button"
                      className="px-4 py-2 bg-black text-white rounded h-10 cursor-pointer"
                      onClick={() => downloadScript()}
                    >
                      Download script
                    </Button>
                  ) : (
                    <button
                      type="button"
                      onClick={nextPage}
                      className="px-4 py-2 bg-black text-white rounded w-25 cursor-pointer"
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

export default ScanCALinux;
