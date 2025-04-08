import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { useState } from "react";

const ScanCAWindows = () => {
  const [page, setPage] = useState(1);
  const [formData, setFormData] = useState({
    // General Info
    scanName: "",
    projectName: "",
    description: "",

    // Target Details
    agent: "",

    /* Agent, Remote access, or upload config -
     * Agent: display only download button
     * Remote access: User input and upload button sidebyside
     *                Get credentials - password, kerberos, LM Hash, NTLM Hash (if windows)
     *                                - password, kerberos public key, certificate (if linux)
     * Upload: User input and upload button sidebyside
     */

    target: "",
    password: "",
    kerberos: "",
    LMHash: "",
    NTLMHash: "",

    //Get compliance info
    // __________________

    //Scan settings
    schedule: "",
    notification: "",
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
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
            <input
              type="text"
              name="scanName"
              placeholder="Scan Name"
              value={formData.scanName}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
            {/* Add other general info inputs */}
          </div>
        );
      case 2:
        return (
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">User Information</h2>
            <input
              type="text"
              name="username"
              placeholder="Username"
              value={formData.scanName}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
            {/* Add other user info inputs */}
          </div>
        );
      case 3:
        return (
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">System Information</h2>
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
            <h2 className="text-xl font-semibold">Compliance Information</h2>
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
      <div className="flex-1 flex flex-col pr-8 pl-8">
        <Header title="Windows Scan"/>

        <Card className="w-full h-[calc(100vh-120px)] mt-4">
          <CardContent className="w-full p-6 pl-12">
            <div className="w-[80%] space-y-6">

            <h1 className="text-2xl font-bold mb-6">
              Windows Configuration Audit Scan
            </h1>

            {/* Progress indicator */}
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
