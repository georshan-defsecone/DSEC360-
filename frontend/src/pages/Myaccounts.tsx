import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { useState } from "react";
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"

const Myaccounts = () => {
  const [page, setPage] = useState(1);
  const [formData, setFormData] = useState({
    // General Info
    fullname: "",
    email: "",
   

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
            <h2 className="text-xl font-semibold">User Info</h2>
            <input
              type="text"
              name="fullname"
              placeholder="fullname"
              value={formData.fullname}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
             <input
              type="text"
              name="email"
              placeholder="email"
              value={formData.email}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
             <h2 className="text-xl font-semibold">User Info</h2>
            <input
              type="text"
              name="fullname"
              placeholder="fullname"
              value={formData.fullname}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
             <input
              type="text"
              name="email"
              placeholder="email"
              value={formData.email}
              onChange={handleInputChange}
              className="w-full p-2 border rounded"
            />
            {/* Add other general info inputs */}
          </div>
        );
      case 2:
        return (
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Api Keys</h2>
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
      default:
        return null;
    }
  };

  return (<>
    <div className="flex h-screen text-black">
    <Sidebar settings={true} scanSettings={false} homeSettings={false} />
    <div className="flex-1 flex flex-col ml-64 p-8 ">
      <Header title="My Account" />
      <Card className="min-h-130">
        <CardContent className="p-2 pl-12">
          <div className="flex flex-col items-start  space-y-10"> {/* Add space between rows */}
            <h2 className="text-xl font-bold">User Info</h2>
            {/* Row 1 */}
            <div className="flex items-center">
              <p className="text-lg font-semibold w-40">Full Name:</p> {/* Adjust width of label */}
              <Input type="text" className="w-60" placeholder="" />
            </div>

            {/* Row 2 */}
            <div className="flex items-center">
              <p className="text-lg font-semibold w-40">Email:</p>
              <Input type="text" className="w-60" placeholder="" />
            </div>

            <h2 className="text-xl font-bold">Change Password</h2>


            {/* Row 3 */}
            <div className="flex items-center">
              <p className="text-lg font-semibold w-40">Current Password:</p>
              <Input type="text" className="w-60" placeholder="" />
            </div>

            {/* Row 4 */}
            <div className="flex items-center">
              <p className="text-lg font-semibold w-40">New Password:</p>
              <Input type="text" className="w-60" placeholder="" />
            </div>

            {/* Row 5 */}
                  {/* Row 6 */}
           
          </div>
        </CardContent>
      </Card>
      <Button variant="outline" className="w-20 mt-6 ml-auto mr-6">Save</Button>

    </div>
  </div></>
  );
};

export default Myaccounts;
