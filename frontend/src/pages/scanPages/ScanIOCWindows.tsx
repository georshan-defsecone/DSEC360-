import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import Breadcrumbs from "@/components/ui/Breadcrumbs";
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
import FileUploader from "@/components/FileUploader";
import { toast, Toaster } from "sonner";
import { CheckCircle2 } from "lucide-react";
import api from "../api";
const ScanIOCWindows = () => {
    const [IOCdata, setIOCdata] = useState([]);
    const [errors, setErrors] = useState<string | boolean>("");
    const [fileIPs, setFileIPs] = useState<string[]>([]);

    const formPages = ["●", "●", "●", "●", "●"];
    const formPagesAgent = ["●", "●", "●", "●"];

    const [page, setPage] = useState(1);
  const [userName, setUserName] = useState("");

    const [formData, setFormData] = useState({
        // General Info
        scanName: "",
        projectName: "",
        description: "",

        // Target Details
        auditMethod: "",
        target: "",
        targetList: [],
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

        globalCredentials: {
            neverSendCredentials: "false",
            dontUseNTLMv1: "false",
            startRemoteRegistryService: "false",
            enableAdministrativeShares: "false",
            startServerService: "false",
        },

        //Get control info
        IOCcontrols: {} as Record<string, boolean>,

        //Scan settings
        schedule: "",
        scheduleFrequency: "",
        scheduleStartDate: "",
        scheduleStartTime: "",
        scheduleTimezone: "",
        notification: "",
        notificationEmail: "",
    });

        const getUncheckedComplianceItems = () => {
    return Object.keys(formData.IOCcontrols).filter(
        (iocName) => !formData.IOCcontrols[iocName]
    );
};

    const downloadScript = async () => {
        const uncheckedComplianceItems = getUncheckedComplianceItems();
    const scanPayload = {
        project_name: formData.projectName,
        scan_name: formData.scanName,
        scan_author: userName || "unknown",
        scan_status: "Pending",

        scan_type: "Compromise Assessment",
        scan_data: {
            scanType: "Compromise Assessment",
            description: formData.description,
            category: "windows",
            auditMethod: formData.auditMethod,
            target: formData.target,
            targetList: formData.targetList,
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

            globalCredentials: {
                neverSendCredentials: formData.globalCredentials.neverSendCredentials,
                dontUseNTLMv1: formData.globalCredentials.dontUseNTLMv1,
                startRemoteRegistryService: formData.globalCredentials.startRemoteRegistryService,
                enableAdministrativeShares: formData.globalCredentials.enableAdministrativeShares,
                startServerService: formData.globalCredentials.startServerService,
            },

            IOCcontrols: formData.IOCcontrols,

            schedule: formData.schedule,
            scheduleFrequency: formData.scheduleFrequency,
            scheduleStartDate: formData.scheduleStartDate,
            scheduleStartTime: formData.scheduleStartTime,
            scheduleTimezone: formData.scheduleTimezone,
            notification: formData.notification,
            notificationEmail: formData.notificationEmail,

            uncheckedComplianceItems: uncheckedComplianceItems, // If you have this available in the component
        },
    };

    try {
        const response = await api.post("/scans/create-scan/", scanPayload, {
            responseType: "blob",
        });

        // Try to get the filename from the response headers
        const contentDisposition = response.headers["content-disposition"];
        let filename = "IOC_Script.ps1";


      if (contentDisposition) {
        const match = contentDisposition.match(/filename="?([^"]+)"?/);
        if (match?.[1]?.trim()) filename = match[1].trim();
      }

        // Trigger the download
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement("a");
        link.href = url;
        link.setAttribute("download", filename);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);

        console.log("[+] Script downloaded successfully.");

    } catch (error) {
        console.error("Error downloading script:", error.response?.data || error.message);
        alert("Failed to download the script.");
    }
};



    const validatePage1 = () => {
        return (
            formData.scanName.trim() !== "" &&
            formData.projectName.trim() !== ""
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
        if (!formData.auditMethod) return "Please select an audit method.";

        if (formData.auditMethod === "remoteAccess") {
            if (!formData.target) return "Target IP is required.";
            if (!validateTargetIPInput(formData.target))
                return "IP Address incorrect.";
            if (!formData.authMethod) return "Authentication method required.";

            switch (formData.authMethod) {
                case "password":
                    if (!(formData.username && formData.password))
                        return "Username and password required.";
                    break;
                case "ntlm":
                    if (
                        !(
                            formData.username &&
                            formData.ntlmHash &&
                            formData.domain
                        )
                    )
                        return "NTLM credentials required.";
                    break;
                case "kerberos":
                    if (
                        !(
                            formData.username &&
                            formData.password &&
                            formData.kdc &&
                            formData.kdcPort &&
                            formData.domain
                        )
                    ) {
                        return "Kerberos credentials incomplete.";
                    }
                    break;
                case "lm":
                    if (
                        !(
                            formData.username &&
                            formData.lmHash &&
                            formData.domain
                        )
                    )
                        return "LM credentials required.";
                    break;
                default:
                    return "Invalid authentication method.";
            }
        }

        return true; // Valid for agent and uploadConfig
    };

    useEffect(() => {
        const fetchIOCdata = async () => {
            try {
                const response1 = await api.get("users/userinfo");
setUserName(response1.data.username);
        const response = await api.get(
                    "/scans/compliance/ioc/windows/"
                );
                console.log(response.data);
                setIOCdata(response.data);

                const initalControls = response.data.reduce(
                    (acc: Record<string, boolean>, ioc: any) => {
                        const key = ioc["IOC Names "].trim();
                        acc[key] = true;
                        return acc;
                    },
                    {}
                );

                setFormData((prev) => ({
                    ...prev,
                    IOCcontrols: initalControls,
                }));
            } catch (error) {
                console.error("Error fetching IOC data:", error);
                setErrors("Failed to fetch IOC data. Please try again later.");
            }
        };

        fetchIOCdata();
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
                ...((prev[field as keyof typeof prev] || {}) as Record<
                    string,
                    string
                >),
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

    const handleCheckboxChange = (iocName: string) => {
        setFormData((prev) => ({
            ...prev,
            IOCcontrols: {
                ...prev.IOCcontrols,
                [iocName]: !prev.IOCcontrols[iocName],
            },
        }));
    };

    const nextPage = () => {
        let validationResult: string | boolean = false;

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
                validationResult = true
                break;
            case 5:
                validationResult = true;
                break;
            default:
                validationResult = false;
        }

        if (validationResult !== true) {
            setErrors(validationResult);
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
    const response = await api.post("/api/create-scan/", {
      project_name: formData.projectName,
      scan_name: formData.scanName,
      scan_author: userName, // adjust as needed
      scan_status: "Pending",       // or dynamic status
      scan_type:"Compromise Assessment",

      scan_data: {
        scanType:"Compromise Assessment",
        description: formData.description,

        // Target Details
        auditMethod: formData.auditMethod,
        target: formData.target,
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

        // Global Credentials
        globalCredentials: {
          neverSendCredentials: formData.globalCredentials.neverSendCredentials,
          dontUseNTLMv1: formData.globalCredentials.dontUseNTLMv1,
          startRemoteRegistryService: formData.globalCredentials.startRemoteRegistryService,
          enableAdministrativeShares: formData.globalCredentials.enableAdministrativeShares,
          startServerService: formData.globalCredentials.startServerService,
        },

        // IOC Controls
        IOCcontrols: formData.IOCcontrols,

        // Scan Settings
        schedule: formData.schedule,
        scheduleFrequency: formData.scheduleFrequency,
        scheduleStartDate: formData.scheduleStartDate,
        scheduleStartTime: formData.scheduleStartTime,
        scheduleTimezone: formData.scheduleTimezone,
        notification: formData.notification,
        notificationEmail: formData.notificationEmail,
      },
    });

    console.log("Scan created:", response.data);
    alert("Scan created successfully!");

    // Optionally reset form:
    // setFormData(initialFormData);
  } catch (error) {
    console.error("Error creating scan:", error.response?.data || error.message);
    toast.success("Scan created succesfully", {
  icon: <CheckCircle2 className="text-green-500" />,
});
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
                        <h2 className="text-xl font-semibold">
                            General Information
                        </h2>

                        <div className="flex items-center">
                            <p className="block w-70">Project Name:</p>

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
                        <h2 className="text-xl font-semibold">
                            Target Details
                        </h2>
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
                                    <SelectItem value="remoteAccess">
                                        Remote Access
                                    </SelectItem>
                                    <SelectItem value="uploadConfig">
                                        Upload Config
                                    </SelectItem>
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
                                        //className="w-full p-2 border rounded"
                                    />

                                    <FileUploader
                                        onFileParsed={handleFileParsed}
                                    ></FileUploader>
                                </div>

                                <div className="flex justify-start items-center mb-4">
                                    <p className="block w-70 ">
                                        Authentication Method:
                                    </p>
                                    <Select
                                        value={formData.authMethod}
                                        onValueChange={(value) =>
                                            handleInputChange(
                                                value,
                                                "authMethod"
                                            )
                                        }
                                    >
                                        <SelectTrigger className="w-[180px]">
                                            <SelectValue placeholder="Select Auth Method" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectItem value="password">
                                                Password
                                            </SelectItem>
                                            <SelectItem value="ntlm">
                                                NTLM Hash
                                            </SelectItem>
                                            <SelectItem value="lm">
                                                LM Hash
                                            </SelectItem>
                                            <SelectItem value="kerberos">
                                                Kerberos
                                            </SelectItem>
                                        </SelectContent>
                                    </Select>
                                </div>

                                {formData.authMethod === "password" && (
                                    <div className="space-y-4">
                                        <div className="flex items-center">
                                            <p className="block w-70">
                                                Username:
                                            </p>
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
                                            <p className="block w-70">
                                                Password:
                                            </p>
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
                                            <p className="block w-70 ">
                                                Domain:
                                            </p>

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

                                {formData.authMethod === "ntlm" && (
                                    <div className="space-y-4">
                                        <div className="flex items-center">
                                            <p className="block w-70">
                                                Username:
                                            </p>
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
                                            <p className="block w-70">
                                                NTLM Hash:
                                            </p>
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
                                            <p className="block w-70">
                                                Domain:
                                            </p>
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
                                            <p className="block w-70">
                                                Username:
                                            </p>
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
                                            <p className="block w-70">
                                                Password:
                                            </p>
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
                                            <p className="block w-70">
                                                KDC Transport:{" "}
                                            </p>
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
                                            <p className="block w-70">
                                                Domain:
                                            </p>
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
                                {formData.authMethod === "lm" && (
                                    <div className="space-y-4 border-l-2 border-gray-200">
                                        <div className="flex items-center">
                                            <p className="block w-70">
                                                Username:
                                            </p>
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
                                            <p className="block w-70">
                                                LM Hash:
                                            </p>
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
                                            <p className="block w-70">
                                                Domain:
                                            </p>
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
                            </div>
                        )}

                        {formData.auditMethod === "uploadConfig" && (
                            <>
                                <div className="space-y-4">
                                    <div className="flex justify-between items-center">
                                        <Button
                                            type="button"
                                            className="px-4 py-2 bg-black text-white rounded"
                                            onClick={() =>
                                                console.log("Uploading config")
                                            }
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
                        <h3 className="text-xl font-semibold">
                            Global Credentials Settings
                        </h3>
                        <div className="flex items-center">
                            <Checkbox
                                className="mr-4"
                                checked={
                                    formData.globalCredentials
                                        .neverSendCredentials === "true"
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
                                    formData.globalCredentials.dontUseNTLMv1 ===
                                    "true"
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
                            <p>
                                start the remote registry service during the
                                scan
                            </p>
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
                                    formData.globalCredentials
                                        .startServerService === "true"
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
                    </div>
                );
            case 4:
                return (
                    <>
                        <div className="space-y-6">
                            <h2 className="text-xl font-semibold">
                                IOC Controls
                            </h2>
                            <div className="flex flex-col space-y-4">
                                {IOCdata.map((ioc: any) => {
                                    const iocName = ioc["IOC Names "].trim();
                                    return (
                                        <div
                                            key={ioc["ID Number "]}
                                            className="flex items-center space-x-3"
                                        >
                                            <Checkbox
                                                id={`ioc-${ioc["ID Number "]}`}
                                                checked={
                                                    formData.IOCcontrols[
                                                        ioc["IOC Names "]
                                                    ] || false
                                                }
                                                onCheckedChange={() =>
                                                    handleCheckboxChange(
                                                        ioc["IOC Names "]
                                                    )
                                                }
                                            />
                                            <label
                                                htmlFor={`ioc-${ioc["ID Number "]}`}
                                                className="text-sm font-medium leading-none"
                                            >
                                                {ioc["IOC Names "]}
                                            </label>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    </>
                );

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
                                        handleInputChange(
                                            checked.toString(),
                                            "schedule"
                                        )
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
                                                handleInputChange(
                                                    value,
                                                    "scheduleFrequency"
                                                )
                                            }
                                        >
                                            <SelectTrigger className="w-80">
                                                <SelectValue placeholder="Select frequency" />
                                            </SelectTrigger>
                                            <SelectContent>
                                                <SelectItem value="daily">
                                                    Daily
                                                </SelectItem>
                                                <SelectItem value="weekly">
                                                    Weekly
                                                </SelectItem>
                                                <SelectItem value="monthly">
                                                    Monthly
                                                </SelectItem>
                                                <SelectItem value="yearly">
                                                    Yearly
                                                </SelectItem>
                                            </SelectContent>
                                        </Select>
                                    </div>

                                    <div className="flex items-center">
                                        <p className="block w-70">
                                            Start Date:
                                        </p>
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
                                        <p className="block w-70">
                                            Start Time:
                                        </p>
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
                                                handleInputChange(
                                                    value,
                                                    "scheduleTimezone"
                                                )
                                            }
                                        >
                                            <SelectTrigger className="w-80">
                                                <SelectValue placeholder="Select timezone" />
                                            </SelectTrigger>
                                            <SelectContent>
                                                <SelectItem value="IST">
                                                    IST
                                                </SelectItem>
                                                <SelectItem value="UTC">
                                                    UTC
                                                </SelectItem>
                                                <SelectItem value="EST">
                                                    EST
                                                </SelectItem>
                                                <SelectItem value="PST">
                                                    PST
                                                </SelectItem>
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
                                    <p className="font-medium">
                                        Email Notifications
                                    </p>
                                    <p className="text-sm text-gray-500">
                                        Get notified about scan results
                                    </p>
                                </div>
                                <Switch
                                    checked={formData.notification === "true"}
                                    onCheckedChange={(checked) =>
                                        handleInputChange(
                                            checked.toString(),
                                            "notification"
                                        )
                                    }
                                />
                            </div>

                            {formData.notification === "true" && (
                                <div className="space-y-4 pl-4 border-l-2 border-gray-200">
                                    <div className="flex items-center">
                                        <p className="block w-70">
                                            Email Address:
                                        </p>
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
        <>
            <div className="flex h-screen text-black">
                <Sidebar
                    settings={false}
                    scanSettings={true}
                    homeSettings={false}
                />
                <div className="flex-1 flex flex-col pr-8 pl-8 ml-64 pt-20">
                    <Header title="Windows Compromise Assessment Scan" />

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
                                                page === 1
                                                    ? "bg-gray-300"
                                                    : "bg-black text-white"
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
                                        ) : formData.auditMethod === "agent" &&
                                          page === 4 ? (
                                            <Button type="button" className="px-4 py-2 bg-black text-white h-10 rounded cursor-pointer" onClick={downloadScript}>
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
        </>
    );
};

export default ScanIOCWindows;
