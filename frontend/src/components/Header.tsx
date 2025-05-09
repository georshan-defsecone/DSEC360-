import { useEffect, useState } from "react";
import { jwtDecode } from "jwt-decode";
import { CircleUserRound, LogOut, User } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";
import { useNavigate } from "react-router-dom";


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

  const handleLogout = () => {
    localStorage.removeItem("access");
    localStorage.removeItem("refresh");
    window.location.href = "/login";
  };

  return (
    <header className="fixed top-0 left-64 w-[calc(100%-16rem)] h-20 bg-white   flex items-center justify-between px-6 z-50">
      {/* Page Title */}
      <div className="text-xl font-bold text-gray-800">{title}</div>

      {/* User Menu */}
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button className="outline-none">
            <CircleUserRound className="w-8 h-8 text-gray-800 hover:text-gray-600" />
          </button>
        </DropdownMenuTrigger>

        <DropdownMenuContent
          className="w-64 mt-2 p-3 rounded-xl shadow-lg bg-white border border-gray-200 right-0"
          align="end" // ensures dropdown doesn't go to corner
        >
          {/* Mini Profile */}
          <div className="flex items-center gap-3 px-2 py-2">
            <div className="bg-gray-100 p-2 rounded-full">
              <CircleUserRound className="w-6 h-6 text-gray-700" />
            </div>
            <div className="text-sm">
              <div className="font-semibold text-gray-800">{username}</div>
              <div className="text-gray-500 text-xs">{email}</div>
            </div>
          </div>

          <DropdownMenuSeparator className="my-2" />

          {/* Horizontal Menu Options in Dropdown Format */}
          <div className="flex items-center justify-between gap-4 px-2 py-1 text-sm">
            <button
              className="flex items-center gap-2 px-3 py-2 bg-white text-black hover:bg-black hover:text-white rounded-md transition-all duration-200 ease-in-out"
              onClick={() => navigate("/settings/myaccounts")}
            >
              <User className="w-4 h-4 transition-transform duration-200" />
              My Profile
            </button>

            <span className="text-gray-300">|</span>

            <button
              onClick={handleLogout}
              className="flex items-center gap-1 text-red-600 hover:text-red-800 transition"
            >
              <LogOut className="h-4 w-4" />
              Logout
            </button>
          </div>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  );

}

