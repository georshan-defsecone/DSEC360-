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
import { Eye, EyeOff } from "lucide-react";
import api from "./api";

const CreateUser = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState("user");

  const handleCreateUser = async () => {
    try {
      const response = await api.post("/users/createuser", {
        username,
        email,
        password,
        is_admin: role === "admin",
      });
      console.log("User created:", response.data);
      alert("User created successfully!");
      // Clear form
      setUsername("");
      setEmail("");
      setPassword("");
      setRole("user");
    } catch (error) {
      console.error("Error creating user:", error);
      alert("Failed to create user.");
    }
  };
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
                  <Input
                    type="text"
                    className="w-60"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                  />
                </div>

                {/* Row 2: Port */}

                {/* Row 3: Username */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Email:</p>
                  <Input
                    type="text"
                    className="w-60"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>

                {/* Row 4: Password */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Password:</p>
                  <div className="relative w-60">
                    <Input
                      type={showPassword ? "text" : "password"}
                      className="w-full pr-10"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
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
                  <Select onValueChange={(value) => setRole(value)}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="Select" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="autodetect">User</SelectItem>
                      <SelectItem value="none">Admin</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <Button
                  variant="outline"
                  className="w-20 mt-6 ml-auto mr-6"
                  onClick={handleCreateUser}
                >
                  Create
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Save Button - Show only if proxy is enabled */}
        </div>
      </div>
    </>
  );
};

export default CreateUser;
