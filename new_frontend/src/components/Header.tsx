import { Link } from "react-router-dom";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuItem,
} from "./ui/dropdown-menu";

function Header() {
  return (
    <header className="flex justify-between items-center p-4 bg-gray-800 text-white">
      <div className="flex items-center space-x-2">
        <img src="/logo.png" alt="Logo" className="w-12 h-12" />
        <h1 className="text-xl font-bold">DSEC360+</h1>
      </div>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button className="px-4 py-2 bg-gray-700 rounded-md">Menu</button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuLabel>My Account</DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuItem asChild>
            <Link to="/profile">Profile</Link>
          </DropdownMenuItem>
          <DropdownMenuItem asChild>
            <Link to="/team">Team</Link>
          </DropdownMenuItem>
          <DropdownMenuItem asChild>
            <Link to="/scan">Scan</Link>
          </DropdownMenuItem>
          <DropdownMenuItem asChild>
            <Link to="/">Home</Link>
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  );
}

export default Header;
