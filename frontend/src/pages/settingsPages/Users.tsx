import { useEffect, useState } from "react";
import { Link } from "react-router-dom"; // Link is still useful for other potential navigations
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from "@/components/ui/dropdown-menu";
import { Pencil, X, MoreVertical, Eye, EyeOff, CheckCircle2 } from "lucide-react"; // Added Eye, EyeOff, CheckCircle2
import { Input } from "@/components/ui/input"; // Added Input
import { // Added Select components
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import api from "@/pages/api"; // Ensure this path is correct
import { toast } from "sonner"; // Assuming sonner is installed and configured

const Users = () => {
  const [users, setUsers] = useState([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [showCreateUserModal, setShowCreateUserModal] = useState(false); // New state for modal

  // State for the Create User form
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState("user");
  const [showPassword, setShowPassword] = useState(false); // For password visibility

  const fetchData = async () => {
    try {
      const response = await api.get("users/");
      setUsers(response.data);
    } catch (error) {
      console.error("Error fetching user data:", error);
      toast.error("Failed to fetch users.", {
        icon: <X className="text-red-500" />,
      });
    }
  };

  useEffect(() => {
    fetchData();
  }, []); // Fetch users on component mount

  const filteredUsers = users.filter((user) =>
    `${user.username} ${user.email}`.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleCreateUser = async () => {
    try {
      await api.post("/users/createuser", {
        username,
        email,
        password,
        is_admin: role === "admin",
      });
      toast.success("User created successfully", {
        icon: <CheckCircle2 className="text-green-500" />,
      });
      // Clear form fields
      setUsername("");
      setEmail("");
      setPassword("");
      setRole("user");
      setShowCreateUserModal(false); // Close the modal
      fetchData(); // Refresh user list
    } catch (error) {
      console.error("Error creating user:", error);
      const errorMessage = error.response?.data?.error || "Failed to create user.";
      toast.error(errorMessage, {
        icon: <X className="text-red-500" />,
      });
    }
  };

  const handleDeleteUser = async (userId) => {
    if (!window.confirm("Are you sure you want to delete this user?")) {
      return;
    }
    try {
      await api.delete(`/users/${userId}/`);
      toast.success("User deleted successfully", {
        icon: <CheckCircle2 className="text-green-500" />,
      });
      fetchData(); // Refresh user list
    } catch (error) {
      console.error("Error deleting user:", error);
      const errorMessage = error.response?.data?.error || "Failed to delete user.";
      toast.error(errorMessage, {
        icon: <X className="text-red-500" />,
      });
    }
  };


  return (
    <div className="flex h-screen text-black pt-24 overflow-hidden">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />

      <div className="flex-1 flex flex-col ml-64 pr-8 pl-8">
        <Header title="Users" />

        <Card className="w-full mt-6 shadow-lg border border-gray-200 bg-white rounded-none">
          <CardContent className="p-5">
            {/* Search and Add User */}
            <div className="flex justify-between items-center mb-4">
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
              <Button
                onClick={() => setShowCreateUserModal(true)} // Open modal
                className="flex items-center gap-2 cursor-pointer rounded-none"
              >
                Add User
              </Button>
            </div>

            <div className="border-b border-gray-300 mb-4" />

            <div className="overflow-y-auto max-h-[500px]">
              <Table>
                <TableHeader>
                  <TableRow className="bg-gray-100 text-gray-700 border-b border-gray-400">
                    <TableHead className="w-[30%] px-4 py-2 text-left">Name</TableHead>
                    <TableHead className="w-[35%] px-4 py-2 text-left">Email</TableHead>
                    <TableHead className="w-[20%] px-4 py-2 text-left">Role</TableHead>
                    <TableHead className="w-[15%] px-4 py-2 text-left">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredUsers.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={4} className="text-center py-4">
                        No users found.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredUsers.map((user, idx) => (
                      <TableRow
                        key={user.id}
                        className={`border-b ${idx % 2 === 0 ? "bg-white" : "bg-gray-50"}`}
                      >
                        <TableCell className="px-4 py-3">{user.username}</TableCell>
                        <TableCell className="px-4 py-3">{user.email}</TableCell>
                        <TableCell className="px-4 py-3">
                          {user.is_admin ? "Admin" : "User"}
                        </TableCell>
                        <TableCell className="px-4 py-3">
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <button className="p-1 rounded hover:bg-gray-200 transition">
                                <MoreVertical size={18} className="cursor-pointer" />
                              </button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem className="cursor-pointer"
                                // Assuming you will have a separate Edit User page or modal later
                                // For now, this just logs to console or you can navigate
                                onClick={() => alert(`Edit user: ${user.username}`)} // Replace with navigate or modal
                              >
                                <Pencil className="mr-2 h-4 w-4" />
                                Edit
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onClick={() => handleDeleteUser(user.id)}
                                className="text-red-600 focus:bg-red-50 cursor-pointer"
                              >
                                <X className="mr-2 h-4 w-4 text-red-600" />
                                Delete
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Create User Modal */}
      {showCreateUserModal && (
        <div className="fixed inset-0  bg-opacity-50 flex items-center justify-center z-50 p-4">
          <Card className="shadow-2xl border rounded-lg p-6 w-full max-w-md bg-white animate-scale-in">
            <CardContent className="space-y-6 p-0">
              <h3 className="text-xl font-semibold text-gray-800 mb-4">Create New User</h3>
              <div className="space-y-3">
                <div>
                  <label htmlFor="username" className="block text-sm text-gray-700 font-medium mb-1">Username:</label>
                  <Input
                    id="username"
                    type="text"
                    className="w-full text-gray-900"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                  />
                </div>
                <div>
                  <label htmlFor="email" className="block text-sm text-gray-700 font-medium mb-1">Email:</label>
                  <Input
                    id="email"
                    type="email"
                    className="w-full text-gray-900"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div>
                  <label htmlFor="password" className="block text-sm text-gray-700 font-medium mb-1">Password:</label>
                  <div className="relative w-full">
                    <Input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      className="pr-10 text-gray-900"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                    />
                    <div
                      className="absolute inset-y-0 right-2 flex items-center cursor-pointer"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff size={20} className="text-gray-500" /> : <Eye size={20} className="text-gray-500" />}
                    </div>
                  </div>
                </div>
                <div>
                  <label htmlFor="role" className="block text-sm text-gray-700 font-medium mb-1">Role:</label>
                  <Select onValueChange={(value) => setRole(value)} value={role}>
                    <SelectTrigger id="role" className="w-full">
                      <SelectValue placeholder="Select Role" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="user">User</SelectItem>
                      <SelectItem value="admin">Admin</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="flex justify-end gap-3 mt-6">
                <Button variant="outline" className="w-24 rounded-md cursor-pointer" onClick={() => setShowCreateUserModal(false)}>
                  Cancel
                </Button>
                <Button className="w-24 bg-black text-white cursor-pointer hover:bg-gray-800 rounded-md" onClick={handleCreateUser}>
                  Create
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
};

export default Users;