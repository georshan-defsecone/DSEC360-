import { useEffect, useState } from "react";
import { jwtDecode } from "jwt-decode";
import { CircleUserRound, LogOut, User } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";

type DecodedToken = {
  username: string;
  email: string;
  is_admin: boolean;
  exp: number;
};

export default function Header({ title }: { title: string }) {
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
    <header className="w-full px-6 py-6 flex justify-between items-center ">
      <div className="text-xl font-semibold text-gray-800">{title}</div>

      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button className="outline-none">
            <CircleUserRound className="w-8 h-8 text-gray-800 hover:text-gray-600" />
          </button>
        </DropdownMenuTrigger>

        <DropdownMenuContent className="w-64 mt-2 mr-4 p-2 rounded-xl shadow-xl bg-white border border-gray-200">
          {/* Mini Profile Summary */}
          <div className="px-3 py-2">
            <div className="flex items-center space-x-3">
              <div className="bg-gray-100 p-2 rounded-full">
                <CircleUserRound className="w-6 h-6 text-gray-700" />
              </div>
              <div className="text-sm">
                <div className="font-semibold text-gray-800">{username}</div>
                <div className="text-gray-500 text-xs">{email}</div>
              </div>
            </div>
          </div>

          <DropdownMenuSeparator className="my-2" />

          {/* Menu Options */}
          <DropdownMenuItem
            onClick={() => (window.location.href = "/settings/myaccounts")}
            className="cursor-pointer text-sm text-gray-800 hover:bg-gray-100"
          >
            <User className="mr-2 h-4 w-4" />
            My Profile
          </DropdownMenuItem>

          <DropdownMenuItem
            onClick={handleLogout}
            className="cursor-pointer text-sm text-red-600 hover:bg-red-50"
          >
            <LogOut className="mr-2 h-4 w-4" />
            Logout
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  );
}
