import React from "react";
import {
  Home,
  Info,
  Phone,
  Settings,
  User,
  Briefcase,
  HelpCircle,
} from "lucide-react"; // Importing icons

const Sidebar = () => {
  return (
    <aside className="h-screen w-64 bg-gray-900 text-white p-5 flex flex-col">
      <h2 className="text-2xl font-bold mb-6">My Sidebar</h2>

      <nav className="space-y-6">
        {/* Section 1: Main Navigation */}
        <div>
          <h3 className="text-gray-400 uppercase text-sm mb-3">Main</h3>
          <ul className="space-y-3">
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
        </div>

        {/* Section 2: User Management */}
        <div>
          <h3 className="text-gray-400 uppercase text-sm mb-3">
            User Management
          </h3>
          <ul className="space-y-3">
            <li className="flex items-center space-x-3 hover:text-gray-300 cursor-pointer">
              <User size={20} />
              <span>Profile</span>
            </li>
            <li className="flex items-center space-x-3 hover:text-gray-300 cursor-pointer">
              <Briefcase size={20} />
              <span>Teams</span>
            </li>
          </ul>
        </div>

        {/* Section 3: Settings & Help */}
        <div>
          <h3 className="text-gray-400 uppercase text-sm mb-3">
            Settings & Help
          </h3>
          <ul className="space-y-3">
            <li className="flex items-center space-x-3 hover:text-gray-300 cursor-pointer">
              <Settings size={20} />
              <span>Settings</span>
            </li>
            <li className="flex items-center space-x-3 hover:text-gray-300 cursor-pointer">
              <HelpCircle size={20} />
              <span>Help & Support</span>
            </li>
          </ul>
        </div>
      </nav>
    </aside>
  );
};

export default Sidebar;
