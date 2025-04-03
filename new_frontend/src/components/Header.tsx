import { Link, useNavigate } from "react-router-dom";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuItem,
} from "@radix-ui/react-dropdown-menu";
import { FaUser, FaUsers, FaCog, FaSignOutAlt } from "react-icons/fa";

function Header() {
  const navigate = useNavigate();

  const performLogout = () => {
    // Clear user authentication data from local storage
    localStorage.removeItem("authToken");
    // Perform any additional cleanup if necessary
  };

  const handleLogout = () => {
    performLogout();
    navigate("/");
  };

  return (
    <header className="flex justify-between items-center p-4 bg-gray-800 text-white fixed top-0 left-0 right-0">
      <div className="flex items-center space-x-2">
        <img src="/logo.png" alt="Logo" className="w-12 h-12" />
        <h1 className="text-xl font-bold">DSEC360+</h1>
      </div>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button className="px-4 py-2 bg-gray-700 rounded-md flex items-center space-x-2">
            <FaUser />
            <span>USER</span>
          </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent className="w-56 bg-white shadow-lg rounded-md">
          <DropdownMenuLabel className="flex items-center space-x-2 px-4 py-2 text-gray-700">
            <FaUser />
            <span>Account</span>
          </DropdownMenuLabel>
          <DropdownMenuSeparator className="h-px bg-gray-200" />
          <DropdownMenuItem asChild>
            <Link
              to="/profile"
              className="flex justify-between items-center px-4 py-2 text-gray-700 hover:bg-gray-100"
            >
              <span className="flex items-center space-x-2">
                <FaUser />
                <span>Profile</span>
              </span>
              <span>|</span>
              <span>Manage</span>
            </Link>
          </DropdownMenuItem>
          <DropdownMenuItem asChild>
            <Link
              to="/team"
              className="flex justify-between items-center px-4 py-2 text-gray-700 hover:bg-gray-100"
            >
              <span className="flex items-center space-x-2">
                <FaUsers />
                <span>Team</span>
              </span>
              <span>|</span>
              <span>Manage</span>
            </Link>
          </DropdownMenuItem>
          <DropdownMenuItem asChild>
            <Link
              to="/settings"
              className="flex justify-between items-center px-4 py-2 text-gray-700 hover:bg-gray-100"
            >
              <span className="flex items-center space-x-2">
                <FaCog />
                <span>Settings</span>
              </span>
              <span>|</span>
              <span>Manage</span>
            </Link>
          </DropdownMenuItem>
          <DropdownMenuSeparator className="h-px bg-gray-200" />
          <DropdownMenuItem asChild>
            <button
              onClick={handleLogout}
              className="flex items-center px-4 py-2 text-red-500 hover:bg-gray-100 w-full text-left"
            >
              <FaSignOutAlt />
              <span>Logout</span>
            </button>
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  );
}

export default Header;
