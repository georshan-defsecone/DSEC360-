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
import { Pencil, X, Plus } from "lucide-react";
import api from "@/pages/api";

const Users = () => {
  const [users, setUsers] = useState([]);
  const [currentPage, setCurrentPage] = useState(1);
  const usersPerPage = 10;

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

  const indexOfLastUser = currentPage * usersPerPage;
  const indexOfFirstUser = indexOfLastUser - usersPerPage;
  const currentUsers = users.slice(indexOfFirstUser, indexOfLastUser);
  const totalPages = Math.ceil(users.length / usersPerPage);

  const handleNextPage = () => {
    if (currentPage < totalPages) {
      setCurrentPage(currentPage + 1);
    }
  };

  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  return (
    <>
      <div className="flex h-screen overflow-hidden text-black pt-24">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64 overflow-hidden">
          <Header title="Users" />
          <div className="flex justify-end mt-4 mb-2">
            <Link to="/settings/users/createuser">
              <Button className="flex items-center gap-2">
                <Plus size={16} /> Add User
              </Button>
            </Link>
          </div>

          {/* Scrollable Table Container */}
          <div className="overflow-y-auto max-h-[calc(100vh-260px)] border rounded-md">
            <Table className="bg-white text-black">
              
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {currentUsers.map((user) => (
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

          {/* Pagination Controls */}
          <div className="flex justify-center items-center mr-12 mt-4 gap-4">
            <Button onClick={handlePrevPage} disabled={currentPage === 1}>
              Previous
            </Button>
            <span className="text-sm">
              Page {currentPage} of {totalPages}
            </span>
            <Button onClick={handleNextPage} disabled={currentPage === totalPages}>
              Next
            </Button>
          </div>
        </div>
      </div>
    </>
  );
};

export default Users;
