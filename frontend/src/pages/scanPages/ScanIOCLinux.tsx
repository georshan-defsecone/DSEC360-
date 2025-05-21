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
const ScanIOCLinux = () => {
  const [IOCdata, setIOCdata] = useState([]);
  const [errors, setErrors] = useState("");

  const formPages = [
    "General Info",
    "Target Details",
    "Controls",
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
    target: "",
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
    elevatePrivilege: "",
    port: "",
    clientVersion: "",
    attemptLeastPrivilege: "false",

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

  const validatePage1 = () => {
    return (
      formData.scanName.trim() !== "" &&
      formData.projectName.trim() !== ""
    );
  };
  
  const validatePage2 = () => {
    if (!formData.auditMethod) return false;
  
    if (formData.auditMethod === "remoteAccess") {
      if (!formData.target) return false;
      if (!formData.authMethod) return false;
  
      // Validate based on authentication method
      switch (formData.authMethod) {
        case "password":
          if (!formData.username || !formData.password) return false;
          break;
        case "publicKey":
          if (!formData.username || !formData.privateKeyPassphrase) return false;
          break;
        case "certificate":
          if (!formData.username || !formData.privateKeyPassphrase) return false;
          break;
        case "kerberos":
          if (!formData.username || !formData.password || !formData.kdc || 
              !formData.kdcPort || !formData.domain) return false;
          break;
        default:
          return false;
      }
  
      // Validate elevation privilege fields if selected
      if (formData.elevatePrivilege) {
        switch (formData.elevatePrivilege) {
          case ".k5login":
            if (!formData.EP_escalationAccount) return false;
            break;
          case "ciscoEnable":
            if (!formData.EPenablePassword) return false;
            break;
          case "dzdo":
            if (!formData.EP_escalationAccount || !formData.EP_escalationPassword ||
                !formData.EP_dzdoDirectory) return false;
            break;
          case "su":
            if (!formData.EP_suDirectory || !formData.EP_su_login ||
                !formData.EP_escalationPassword) return false;
            break;
          case "pbrun":
            if (!formData.EP_pbrunDirectory || !formData.EPsshUserPassword) return false;
            break;
          case "su+sudo":
            if (!formData.EP_su_sudoDirectory || !formData.EP_su_user ||
                !formData.EP_sudoUser || !formData.EP_escalationPassword) return false;
            break;
        }
      }
    }
  
    return true;
  };

  useEffect(() => {
    const fetchIOCdata = async () => {
      try {
        const response = await api.get("/scans/compliance/ioc/linux/");
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
    let isValid = false;

  switch (page) {
    case 1:
      isValid = validatePage1();
      break;
    case 2:
      isValid = validatePage2();
      break;
    case 3:
      isValid = true
      break;
    case 4:
      isValid = true
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
    e.preventDefault()
    setErrors("")
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

                <div className="flex justify-start items-center mb-8">
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
                </div>
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
          <>
            <div className="space-y-6">
              {renderError()}
              <h2 className="text-xl font-semibold">IOC Controls</h2>
              {errors !== "" ? (
                <>
                  <p className="mb-2 text-red-700 font-semibold">{errors}</p>
                </>
              ) : (
                <></>
              )}
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
                          formData.IOCcontrols[ioc["IOC Names "]] || false
                        }
                        onCheckedChange={() =>
                          handleCheckboxChange(ioc["IOC Names "])
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
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={false} scanSettings={true} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64 pt-20">
          <Header title="Linux Compromise Assessment Scan" />

          <Card className="w-[70%] mt-4 ml-4 shadow-2xl">
            <CardContent className="w-full p-4 px-12">
              <div className="w-auto space-y-6">
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
    </>
  );
};

export default ScanIOCLinux;
