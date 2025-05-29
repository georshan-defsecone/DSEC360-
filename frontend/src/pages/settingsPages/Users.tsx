import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { Pencil, X, Plus } from "lucide-react";
import api from "@/pages/api";
import { Card, CardContent } from "@/components/ui/card";
import { toast } from "sonner";
import { CheckCircle2 } from "lucide-react";

const Users = () => {
  const [users, setUsers] = useState([]);
  const [currentPage, setCurrentPage] = useState(1);
  const usersPerPage = 2;

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
    <div className="flex h-screen text-black pt-24 overflow-hidden">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />

      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title="Users" />

        <div className="flex justify-end mt-4 mb-4">
          <Link to="/settings/users/createuser">
            <Button className="flex items-center gap-2 mr-44">
               Add User
            </Button>
          </Link>
        </div>

        {/* Card Container - no scroll */}
        <div className="space-y-4">
          {currentUsers.map((user) => (
            <Card key={user.id} className="shadow-2xl border rounded-lg p-4 w-[86%]">
              <CardContent className="flex justify-between items-center p-0">
                <div className="space-y-1">
                  <p className="text-sm text-gray-500 font-medium">
                    Name: <span className="text-gray-900">{user.username}</span>
                  </p>
                  <p className="text-sm text-gray-500 font-medium">
                    Email: <span className="text-gray-900">{user.email}</span>
                  </p>
                  <p className="text-sm text-gray-500 font-medium">
                    Role: <span className="text-gray-900">{user.is_admin ? "Admin" : "User"}</span>
                  </p>
                </div>
                <div className="flex gap-3">
                  <Pencil
                    size={18}
                    className="cursor-pointer text-blue-600 hover:scale-110 transition"
                  />
                  <X
                    size={18}
                    className="cursor-pointer text-red-500 hover:scale-110 transition"
                  />
                </div>
              </CardContent>
            </Card>
          ))}
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
  );
};

export default Users;
