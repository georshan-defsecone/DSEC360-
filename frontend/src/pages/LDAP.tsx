import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useState } from "react";
import { Checkbox } from "@/components/ui/checkbox";
import { Button } from "@/components/ui/button";

const LDAP = () => {
  const [bindMethod, setBindMethod] = useState("");

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title="LDAP" />
        <Card className="w-[85%]">
          <CardContent className="p-3 pl-8">
            <div className="flex flex-col items-start space-y-6">
              <div className="flex items-center">
                <p className="  w-60">LDAP Server URL:</p>
                <Input
                  type="text"
                  className="w-60"
                  placeholder="enter the domain or ip"
                />
              </div>
              <div className="flex items-center">
                <p className="  w-60">Base DN:</p>
                <Input
                  type="text"
                  className="w-60"
                  placeholder="DC=example,DC=com"
                />
              </div>
              <div className="flex items-center">
                <p className="  w-60">SAM Account Name:</p>
                <Input type="text" className="w-60" />
              </div>
              <div className="flex items-center">
                <p className="  w-60">Bind Method:</p>
                <Select onValueChange={setBindMethod}>
                  <SelectTrigger className="w-[180px]">
                    <SelectValue placeholder="Select" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="authenticating">
                      Bind As Authenticating User
                    </SelectItem>
                    <SelectItem value="servicing">
                      Bind With Servicing Account
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {bindMethod === "authenticating" && (
                <>
                  <div className="flex items-center">
                    <p className="  w-60">Bind DN (if needed):</p>
                    <Input
                      type="text"
                      className="w-60"
                      placeholder="CN=ldap-reader,OU=ServiceAccounts,DC=example,DC=com"
                    />
                  </div>
                  <div className="flex items-center">
                    <p className="  w-60">Bind Password:</p>
                    <Input type="password" className="w-60" />
                  </div>
                </>
              )}

              <div className="flex items-center">
                <p className="  w-60">Group Base DN:</p>
                <Input
                  type="text"
                  className="w-60"
                  placeholder="OU=Groups,DC=example,DC=com"
                />
              </div>
              <div className="flex items-center">
                <p className="  w-60">Admin Group Name:</p>
                <Input type="text" className="w-60" placeholder="AppAdmins" />
              </div>
              <div className="flex items-center">
                <p className="  w-60">Normal Group Name:</p>
                <Input
                  type="text"
                  className="w-60"
                  placeholder="AppUsers (optional)"
                />
              </div>
              <div className="flex items-center">
                <p className="  w-60">Use SSL:</p>
                <Checkbox
                  className="w-5 h-5 border-gray-400 data-[state=checked]:bg-[#001f3f] data-[state=checked]:text-white"
                  id="checbox ssl"
                />
              </div>
              <div className="flex items-center">
                <p className="  w-60">Port:</p>
                <Input type="number" className="w-60" />
              </div>
              <Button className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition ml-auto mr-6">
                Test
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default LDAP;
