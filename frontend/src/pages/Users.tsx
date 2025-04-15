import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import {
  Table,
  TableBody,
  TableCell,
  TableCaption,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { Plus } from "lucide-react";
import api from "@/pages/api"
import {  Pencil, X } from "lucide-react";


const Users = () => {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await api.get("users/"); // uses baseURL + auth automatically
        setUsers(response.data);
        console.log(response.data);
      } catch (error) {
        console.error("Error fetching user data:", error);
      }
    };

    fetchData();
  }, []);

  return (
    <>
      <div className="flex h-screen text-black pt-24">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="Users" />
          <div className="flex justify-end mt-4 mb-2">
            <Link to="/settings/users/createuser">
              <Button className="flex items-center gap-2">
                Add User
              </Button>
            </Link>
          </div>
          <Table className="bg-white text-black">
            <TableCaption>User Info.</TableCaption>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead className="">Role</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((user) => (
                <TableRow key={user.id}>
                  <TableCell className="font-medium">{user.username}</TableCell>
                  <TableCell>{user.email}</TableCell>
                  <TableCell>{user.is_admin ? "Admin" : "User"}</TableCell>
                  <TableCell className="flex justify-end gap-2">
                  <Pencil size={16} className="cursor-pointer text-blue-600" />
                  <X size={16} className="cursor-pointer text-red-500" />
                </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </div>
    </>
  );
};

export default Users;
