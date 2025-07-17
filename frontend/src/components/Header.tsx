import { useEffect, useState } from "react";
import { jwtDecode } from "jwt-decode";
import { LogOut, User } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";
import { useNavigate, Link } from "react-router-dom";
import { Button } from "./ui/button";

type DecodedToken = {
  username: string;
  email: string;
  is_admin: boolean;
  exp: number;
};

export default function Header({ title }: { title: string }) {
  const navigate = useNavigate();
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");

  useEffect(() => {
    const accessToken = localStorage.getItem("access");
    if (accessToken) {
      try {
        const decoded = jwtDecode<DecodedToken>(accessToken);
        setUsername(decoded.username);
        setEmail(decoded.email);
      } catch (err) {
        console.error("Invalid token:", err);
      }
    }
  }, []);

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase();
  };

  const handleLogout = () => {
    localStorage.removeItem("access");
    localStorage.removeItem("refresh");
    window.location.href = "/login";
  };

  return (
    <header className="fixed top-0 left-64 w-[calc(100%-16rem)] h-20 bg-gray-50 flex items-center justify-between pr-16 z-50">
      {/* Page Title */}
      <div className="text-3xl font-bold ml-8 text-gray-800">{title}</div>

      {/* Navigation + User Dropdown */}
      <div className="flex items-center gap-6 ml-auto">
        <Link to="/">
          <Button className="w-25 px-4 py-2 bg-black text-white rounded cursor-pointer">
            Home
          </Button>
        </Link>
        <Link to="/scan">
          <Button className="w-25 px-4 py-2 bg-black text-white rounded cursor-pointer">
            New Scan
          </Button>
        </Link>

        {/* Profile Dropdown with Hover Effects */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="outline-none group" title={email}>
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-gray-600 flex items-center justify-center text-white text-sm font-bold shadow transition-all duration-200 transform group-hover:scale-105 group-hover:ring-2 group-hover:ring-blue-400 cursor-pointer">
                {getInitials(username || "U")}
              </div>
            </button>
          </DropdownMenuTrigger>

          <DropdownMenuContent
            className="w-64 mt-2 p-3 rounded-xl shadow-lg bg-white border border-gray-200 right-0"
            align="end"
          >
            {/* Mini Profile Info */}
            <div className="flex items-center gap-3 px-2 py-2">
              <div className="bg-gray-100 p-2 rounded-full">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-gray-600 flex items-center justify-center text-white text-sm font-bold shadow">
                  {getInitials(username || "U")}
                </div>
              </div>
              <div className="text-sm">
                <div className="font-semibold text-gray-800">{username}</div>
                <div className="text-gray-500 text-xs">{email}</div>
              </div>
            </div>

            <DropdownMenuSeparator className="my-2" />

            {/* Actions */}
            <div className="flex items-center justify-between gap-4 px-2 py-1 text-sm">
              <button
                className="flex items-center cursor-pointer gap-2 px-3 py-2 bg-white text-black hover:bg-black hover:text-white rounded-md transition-all duration-200 ease-in-out"
                onClick={() => navigate("/settings/myaccounts")}
              >
                <User className="w-4 h-4 " />
                My Profile
              </button>

              <button
                onClick={handleLogout}
                className="flex items-center gap-1 cursor-pointer text-red-600 hover:text-red-800 transition"
              >
                <LogOut className="h-4 w-4" />
                Logout
              </button>
            </div>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
