import React from "react";
import { Home, Info, Phone } from "lucide-react"; // Importing icons

const Sidebar = () => {
  return (
    <aside className="h-screen w-64 bg-gray-900 text-white p-5">
      <h2 className="text-2xl font-bold mb-6">My Sidebar</h2>
      <nav>
        <ul className="space-y-4">
          <li className="flex items-center space-x-3 hover:text-gray-300 cursor-pointer">
            <Home size={20} />
            <span>Home</span>
          </li>
          <li className="flex items-center space-x-3 hover:text-gray-300 cursor-pointer">
            <Info size={20} />
            <span>About</span>
          </li>
          <li className="flex items-center space-x-3 hover:text-gray-300 cursor-pointer">
            <Phone size={20} />
            <span>Contact</span>
          </li>
        </ul>
      </nav>
    </aside>
  );
};

export default Sidebar;
