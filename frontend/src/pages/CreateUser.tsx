import { Card, CardContent } from "@/components/ui/card";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Link } from "react-router-dom";
import { Eye, EyeOff } from "lucide-react";
const CreateUser = () => {
  const [showPassword, setShowPassword] = useState(false);
  return (
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="Create User" />
          <Card className="">
            <CardContent className="p-2 pl-12">
              <div className="flex flex-col items-start space-y-10">
                {/* Toggle Switch */}
                <div className="flex items-center"></div>

                {/* Row 1: Host */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Username:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 2: Port */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Fullname:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 3: Username */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Email:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 4: Password */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Password:</p>
                  <div className="relative w-60">
                    <Input
                      type={showPassword ? "text" : "password"}
                      className="w-full pr-10"
                      placeholder=""
                    />
                    <div
                      className="absolute inset-y-0 right-2 flex items-center cursor-pointer"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                    </div>
                  </div>
                </div>

                {/* Row 5: Auth Method */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Role:</p>
                  <Select>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Select" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="autodetect">User</SelectItem>
                      <SelectItem value="none">Admin</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Row 6: User Agent */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">User Agent:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Save Button - Show only if proxy is enabled */}

          <Button variant="outline" className="w-20 mt-6 ml-auto mr-6">
            Create
          </Button>
        </div>
      </div>
    </>
  );
};

export default CreateUser;
