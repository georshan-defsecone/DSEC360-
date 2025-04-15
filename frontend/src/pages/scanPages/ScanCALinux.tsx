import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import Breadcrumbs from "@/components/ui/Breadcrumbs";
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

import api from "../api";
import { Checkbox } from "@/components/ui/checkbox";

const ScanCALinux = () => {
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
    target: "",
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

  interface ElevatePrivilegeFormProps {
    formData: {
      elevatePrivilege: string;
      EP_escalationAccount: string;
      EP_escalationPassword: string;
      EP_dzdoDirectory: string;
      EP_suDirectory: string;
      EP_pbrunDirectory: string;
      EP_su_sudoDirectory: string;
      EP_su_login: string;
      EP_su_user: string;
      EP_sudoUser: string;
      EPsshUserPassword: string;
      EPenablePassword: string;
    };
    handleInputChange: (
      e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | string,
      field?: string
    ) => void;
  }

  const ElevatePrivilegeForm = ({
    formData,
    handleInputChange,
  }: ElevatePrivilegeFormProps) => {
    return (
      <div className="space-y-4">
        <div className="flex justify-start items-center mb-8">
          <p className="block w-70">Elevate privileges with</p>
          <Select
            value={formData.elevatePrivilege}
            onValueChange={(value) =>
              handleInputChange(value, "elevatePrivilege")
            }
          >
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="Elevate privilege" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="nothing">Nothing</SelectItem>
              <SelectItem value=".k5login">.k5login</SelectItem>
              <SelectItem value="ciscoEnable">Cisco 'enable'</SelectItem>
              <SelectItem value="dzdo">dzdo</SelectItem>
              <SelectItem value="su">su</SelectItem>
              <SelectItem value="pbrun">pbrun</SelectItem>
              <SelectItem value="su+sudo">su+sudo</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {formData.elevatePrivilege === ".k5login" && (
          <div className="space-y-4 pl-4 border-l-2 border-gray-200">
            <div className="flex items-center">
              <p className="block w-70">Escalation Account:</p>
              <Input
                type="text"
                name="EP_escalationAccount"
                placeholder="Enter escalation account"
                value={formData.EP_escalationAccount}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
          </div>
        )}

        {formData.elevatePrivilege === "ciscoEnable" && (
          <div className="space-y-4 pl-4 border-l-2 border-gray-200">
            <div className="flex items-center">
              <p className="block w-70">Enable Password:</p>
              <Input
                type="password"
                name="EPenablePassword"
                placeholder="Enter enable password"
                value={formData.EPenablePassword}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
          </div>
        )}

        {formData.elevatePrivilege === "dzdo" && (
          <div className="space-y-4 pl-4 border-l-2 border-gray-200">
            <div className="flex items-center">
              <p className="block w-70">Escalation Account:</p>
              <Input
                type="text"
                name="EP_escalationAccount"
                placeholder="Enter escalation account"
                value={formData.EP_escalationAccount}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">Escalation Password:</p>
              <Input
                type="password"
                name="EP_escalationPassword"
                placeholder="Enter escalation password"
                value={formData.EP_escalationPassword}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">dzdo Directory:</p>
              <Input
                type="text"
                name="EP_dzdoDirectory"
                placeholder="Enter dzdo directory"
                value={formData.EP_dzdoDirectory}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
          </div>
        )}

        {formData.elevatePrivilege === "su" && (
          <div className="space-y-4 pl-4 border-l-2 border-gray-200">
            <div className="flex items-center">
              <p className="block w-70">su Directory:</p>
              <Input
                type="text"
                name="EP_suDirectory"
                placeholder="Enter su directory"
                value={formData.EP_suDirectory}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">su Login:</p>
              <Input
                type="text"
                name="EP_su_login"
                placeholder="Enter su login"
                value={formData.EP_su_login}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">Escalation Password:</p>
              <Input
                type="password"
                name="EP_escalationPassword"
                placeholder="Enter escalation password"
                value={formData.EP_escalationPassword}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
          </div>
        )}

        {formData.elevatePrivilege === "pbrun" && (
          <div className="space-y-4 pl-4 border-l-2 border-gray-200">
            <div className="flex items-center">
              <p className="block w-70">pbrun Directory:</p>
              <Input
                type="text"
                name="EP_pbrunDirectory"
                placeholder="Enter pbrun directory"
                value={formData.EP_pbrunDirectory}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">SSH User Password:</p>
              <Input
                type="password"
                name="EPsshUserPassword"
                placeholder="Enter SSH user password"
                value={formData.EPsshUserPassword}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
          </div>
        )}

        {formData.elevatePrivilege === "su+sudo" && (
          <div className="space-y-4 pl-4 border-l-2 border-gray-200">
            <div className="flex items-center">
              <p className="block w-70">su+sudo Directory:</p>
              <Input
                type="text"
                name="EP_su_sudoDirectory"
                placeholder="Enter su+sudo directory"
                value={formData.EP_su_sudoDirectory}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">su User:</p>
              <Input
                type="text"
                name="EP_su_user"
                placeholder="Enter su user"
                value={formData.EP_su_user}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">sudo User:</p>
              <Input
                type="text"
                name="EP_sudoUser"
                placeholder="Enter sudo user"
                value={formData.EP_sudoUser}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
            <div className="flex items-center">
              <p className="block w-70">Escalation Password:</p>
              <Input
                type="password"
                name="EP_escalationPassword"
                placeholder="Enter escalation password"
                value={formData.EP_escalationPassword}
                onChange={handleInputChange}
                className="w-80"
                required
              />
            </div>
          </div>
        )}
      </div>
    );
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await api.get("/compliance/linux/"); // Adjust the endpoint as needed
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

  const nextPage = () => {
    if (page < 4) setPage((prev) => prev + 1);
  };

  const prevPage = () => {
    if (page > 1) setPage((prev) => prev - 1);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Form submitted:", formData);
    // Add your submission logic here
  };

  const renderPage = () => {
    switch (page) {
      case 1:
        return (
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">General Information</h2>

            <div className="flex justify-between items-center">
              <p className="block w-40 ">Project Name:</p>

              <Input
                type="text"
                name="projectName"
                placeholder="Project Name"
                value={formData.projectName}
                onChange={handleInputChange}
                required
              />
            </div>

            <div className="flex justify-between items-center">
              <p className="block w-40 ">Scan Name:</p>

              <Input
                type="text"
                name="scanName"
                placeholder="Scan Name"
                value={formData.scanName}
                onChange={handleInputChange}
                required
              />
            </div>

            <div className="flex justify-between items-center">
              <p className="block w-40 ">Project Description:</p>

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
                    <ElevatePrivilegeForm
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
                        name="passphrase"
                        placeholder="Passphrase"
                        value={formData.privateKeyPassphrase}
                        onChange={handleInputChange}
                        className="w-80"
                        required
                      />
                    </div>
                    <ElevatePrivilegeForm
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
      case 4:
        return (
          <div className="space-y-6">
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
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title="Linux Configuration Audit Scan" />

        <Card className="w-full mt-4">
          <CardContent className="w-full p-4 pl-12">
            {errors !== "" ? (
              <>
                <p className="mb-2 text-red-700 font-semibold">{errors}</p>
              </>
            ) : (
              <></>
            )}
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
                    <div className="flex">
                      <button
                        type="submit"
                        className="px-4 py-2 bg-black text-white rounded-l"
                      >
                        Save
                      </button>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <button className="px-3 py-2 bg-black text-white rounded-r flex items-center justify-center">
                            <ChevronDown size={20} />
                          </button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent
                          side="bottom"
                          align="end"
                          alignOffset={1}
                          className="w-28" // Adjust as needed
                        >
                          <DropdownMenuItem className="w-2">
                            Launch
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
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

export default ScanCALinux;
