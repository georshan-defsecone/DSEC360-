import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const SMTP = () => {
  // State to hold selected Auth method
  const [authMethod, setAuthMethod] = useState("none");

  // Handle change in Auth method selection
  const handleAuthMethodChange = (value: string) => {
    setAuthMethod(value);
  };
  return (
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="SMTP" />
          <Card className="">
            <CardContent className="p-2 pl-12">
              <div className="flex flex-col items-start  space-y-10">
                {/* Row 1 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Host:</p>{" "}
                  {/* Adjust width of label */}
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 2 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Port:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 3 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">From:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 4 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Encryption:</p>
                  <Select>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Select" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="no encryption">
                        No encryption
                      </SelectItem>
                      <SelectItem value="force ssl">Force SSL</SelectItem>
                      <SelectItem value="force tls">Force TLS</SelectItem>
                      <SelectItem value="use tls if available">
                        Use TLS If Available
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Row 5 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Hostname:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 6 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Auth method:</p>
                  <Select onValueChange={handleAuthMethodChange}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Theme" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="none">None</SelectItem>
                      <SelectItem value="plain">Plain</SelectItem>
                      <SelectItem value="Login">Login</SelectItem>
                      <SelectItem value="ntlm">NTLM</SelectItem>
                      <SelectItem value="cram md5">CRAM MD5</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                {authMethod !== "none" && (
                  <>
                    <div className="flex items-center">
                      <p className="text-lg font-semibold w-40">Username:</p>
                      <Input type="text" className="w-60" placeholder="Enter username" />
                    </div>

                    <div className="flex items-center">
                      <p className="text-lg font-semibold w-40">Password:</p>
                      <Input type="password" className="w-60" placeholder="Enter password" />
                    </div>
                  </>
                )}



              </div>
            </CardContent>
          </Card>
          <Button variant="outline" className="w-20 mt-6 ml-auto mr-6">
            Save
          </Button>
        </div>
      </div>
    </>
  );
};

export default SMTP;
