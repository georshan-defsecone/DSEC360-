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
import api from "../api";
import { toast } from "sonner";
import { CheckCircle2 } from "lucide-react";

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
      toast.success("User created successfully", {
  icon: <CheckCircle2 className="text-green-500" />,
});
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
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title="Create User" />
        
        <Card className="shadow-2xl border rounded-lg p-6 w-[96%] mt-6">
          <CardContent className="space-y-6 p-0">
            <div className="space-y-3">
              <p className="text-sm text-gray-500 font-medium">
                Username:{" "}
                <Input
                  type="text"
                  className="w-72 mt-1 text-gray-900"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                />
              </p>
              <p className="text-sm text-gray-500 font-medium">
                Email:{" "}
                <Input
                  type="email"
                  className="w-72 mt-1 text-gray-900"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </p>
              <p className="text-sm text-gray-500 font-medium">
                Password:{" "}
                <div className="relative w-72 mt-1">
                  <Input
                    type={showPassword ? "text" : "password"}
                    className="pr-10 text-gray-900"
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
              </p>
              <p className="text-sm text-gray-500 font-medium">
                Role:{" "}
                <Select onValueChange={(value) => setRole(value)} value={role}>
                  <SelectTrigger className="w-72 mt-1">
                    <SelectValue placeholder="Select Role" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="user">User</SelectItem>
                    <SelectItem value="admin">Admin</SelectItem>
                  </SelectContent>
                </Select>
              </p>
            </div>

            <div className="flex justify-end">
              <Button variant="outline" className="w-24 bg-black text-white hover:bg-gray-800" onClick={handleCreateUser}>
                Create
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default CreateUser;
