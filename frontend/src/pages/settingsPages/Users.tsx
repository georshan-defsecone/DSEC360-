import { useEffect, useState } from "react";
import { useNavigate, Link } from "react-router-dom";
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
import { Pencil, X } from "lucide-react";
import api from "@/pages/api";

const Users = () => {
  const [users, setUsers] = useState([]);
  const [searchTerm, setSearchTerm] = useState("");
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await api.get("users/");
        setUsers(response.data);
      } catch (error) {
        console.error("Error fetching user data:", error);
      }
    };
    fetchData();
  }, []);

  const filteredUsers = users.filter((user) =>
    `${user.username} ${user.email}`.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex h-screen text-black pt-24 overflow-hidden">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />

      <div className="flex-1 flex flex-col ml-64 pr-8 pl-8">
        <Header title="Users" />

        <div className="flex justify-end mt-4 mb-4">
          <Link to="/settings/users/createuser">
            <Button className="flex items-center gap-2 mr-10">Add User</Button>
          </Link>
        </div>

        <Card className="w-full shadow-lg border border-gray-200 bg-white rounded-none">
          <CardContent className="p-5">
            <div className="flex justify-between items-center mb-2">
              <h2 className="text-xl font-semibold text-gray-800">Users</h2>
              <input
                type="text"
                placeholder="Search..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
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
                        className={`border-b ${
                          idx % 2 === 0 ? "bg-white" : "bg-gray-50"
                        }`}
                      >
                        <TableCell className="px-4 py-3">{user.username}</TableCell>
                        <TableCell className="px-4 py-3">{user.email}</TableCell>
                        <TableCell className="px-4 py-3">
                          {user.is_admin ? "Admin" : "User"}
                        </TableCell>
                        <TableCell className="px-4 py-3">
                          <div className="flex gap-3">
                            <Pencil
                              size={18}
                              className="cursor-pointer text-blue-600 hover:scale-110 transition"
                              onClick={() => navigate(`/settings/users/edit/${user.id}`)}
                            />
                            <X
                              size={18}
                              className="cursor-pointer text-red-500 hover:scale-110 transition"
                              onClick={() => console.log("Delete logic here")}
                            />
                          </div>
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
    </div>
  );
};

export default Users;
