import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const ScanCAWindows = () => {
  const [page, setPage] = useState(1);
  const [formData, setFormData] = useState({
    // General Info
    scanName: "",
    projectName: "",
    description: "",

    // Target Details
    auditMethod: "",

    /* Audit Method can be: Agent, Remote access, or upload config -
     * Agent: display only download button
     * Remote access: User input and upload button sidebyside
     *                Get credentials - password, kerberos, LM Hash, NTLM Hash (if windows)
     *                                - password, kerberos public key, certificate (if linux)
     * Upload: User input and upload button sidebyside
     */

    target: "",
    authMethod: "",
    /*
     * Authentication method can be: password, NTLM hash, LM hash, Kerberos etc.
     * If password: get username and password
     * If NTLM hash: get username and NTLM hash and domain
     * If LM hash: get username and LM hash and domain
     * If Kerberos: get username, password, KDC, KDC port, KDC tranport and domain
     */
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

    //Get compliance info
    // __________________

    //Scan settings
    schedule: "",
    notification: "",
  });

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
    console.log("Form data updated:", formData);
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
              <p className="block w-40 ">Scan Name:</p>

              <Input
                type="text"
                name="scanName"
                placeholder="Scan Name"
                value={formData.scanName}
                onChange={handleInputChange}
                //className="w-full p-2 border rounded"
              />
            </div>

            <div className="flex justify-between items-center">
              <p className="block w-40 ">Project Name:</p>

              <Input
                type="text"
                name="projectName"
                placeholder="Project Name"
                value={formData.projectName}
                onChange={handleInputChange}
                //className="w-full p-2 border rounded"
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
                    <SelectContent>
                      <SelectItem value="password">Password</SelectItem>
                      <SelectItem value="ntlm">NTLM Hash</SelectItem>
                      <SelectItem value="lm">LM Hash</SelectItem>
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
                      />
                    </div>
                  </div>
                )}

                {formData.authMethod === "ntlm" && (
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
                      />
                    </div>
                  </div>
                )}
                {formData.authMethod === "lm" && (
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
            <h2 className="text-xl font-semibold">Compliance Information</h2>
            <input
              type="text"
              name="hostname"
              placeholder="Hostname"
              value={formData.scanName}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
            {/* Add other system info inputs */}
          </div>
        );
      case 4:
        return (
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Scan Settings</h2>
            <input
              type="text"
              name="framework"
              placeholder="Framework"
              value={formData.scanName}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
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
        <Header title="Windows Scan" />

        <Card className="w-full mt-4">
          <CardContent className="w-full p-6 pl-12">
            <div className="w-[80%] space-y-6">
              <h1 className="text-2xl font-bold mb-6">
                Windows Configuration Audit Scan
              </h1>

              {/* Progress indicator
            <div className="flex justify-start gap-8 mb-8">
              {[1, 2, 3, 4].map((step) => (
                <div
                  key={step}
                  className={`w-8 h-8 rounded-full flex items-center justify-center
                                ${
                                  page >= step
                                    ? "bg-black text-white"
                                    : "bg-gray-200"
                                }`}
                >
                  {step}
                </div>
              ))}
            </div>

            {*/}

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

                  {page === 4 ? (
                    <button
                      type="submit"
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

export default ScanCAWindows;
