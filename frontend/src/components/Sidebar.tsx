import { Settings,LogOut } from "lucide-react";
import { Link } from "react-router-dom";
import logo from "@/assets/logo.png";
import "@/styles/sidebar.css"
import { jwtDecode  } from "jwt-decode"
import { useEffect, useState } from 'react';


type SidebarProps = {
  scanSettings: boolean;
  homeSettings: boolean;
  settings: boolean;
};

const ScanSettingSidebar = () => {
  return (
    <nav className="space-y-2">
      <h1 className="block w-full text-left px-4 py-2 font-semibold">
        Configuration Audit
      </h1>
      <Link to="/scan/windows">
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          Windows
        </button>
      </Link>
      <Link to="/scan/linux">
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          Linux
        </button>
      </Link>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Firewall
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Web Servers & Application Servers
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Networks Devices
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Database
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Cloud
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Containers & Orchestration
      </button>
      <h1 className="block w-full text-left px-4 py-2 font-semibold">
        Compromise Assessment
      </h1>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Windows
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Linux
      </button>
    </nav>
  );
};

const SettingSidebar = () => {
  return (<>
    <nav className="space-y-2">
      <Link to={"/settings/about"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          About
        </button>
      </Link>
      <Link to={"/settings/advance"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          Advance
        </button>
      </Link>
      <Link to={"/settings/proxyserver"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          Proxy Server
        </button>
      </Link>
      <Link to={"/settings/smtp"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          SMTP Server
        </button>
      </Link>
      <Link to={"/settings/ldap"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          LDAP
        </button>
      </Link>
    </nav>
    <nav className="mt-7">
      <Link to={"/settings/myaccounts"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          My accounts
        </button>
      </Link>
      <Link to={"/settings/users"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          Users
        </button>
      </Link>
    </nav> </>
  );
};

const HomeSettingSidebar = () => {

  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    const access = localStorage.getItem("access");
    if (access) {
      try {
        const decoded = jwtDecode(access);
        setIsAdmin(decoded?.is_admin);
      } catch (e) {
        console.error("Invalid token:", e);
      }
    }
  }, []);

  return (
    <>
      <nav className="space-y-2">
        <Link to={"/"}>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
            My Projects
          </button>
        </Link>
        {isAdmin && (
          <Link to={"/dashboard/allprojects"}>
            <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
              All Projects
            </button>
          </Link>
        )}

        <Link to={"/dashboard/results"}>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
            Results
          </button>
        </Link>

        <Link to={"/dashboard/trash"}>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
            Trash
          </button>
        </Link>
      </nav>
    </>
  );
};


const handleLogout = () => {
  // Debugging: Check what's in localStorage
  console.log("Before logout:", localStorage);

  // Remove all relevant items
  localStorage.removeItem("access");
  localStorage.removeItem("refresh");
  localStorage.removeItem("accessToken");
  localStorage.removeItem("refreshToken");

  // Optionally clear all storage (careful!)
  // localStorage.clear(); // Uncomment if you want to clear everything

  // Debugging: Confirm it's removed
  console.log("After logout:", localStorage);

  // Redirect to login page
  window.location.href = "/login";
};



const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {
  return (
    <div className="fixed top-0 left-0 h-screen w-64 flex flex-col p-6 justify-between  z-10 bg-white ">
      <div>
        <div className="flex items-center mb-6">
          <img src={logo} alt="Logo" className="w-10" />
          <h2 className="text-2xl font-bold ml-3">DSEC360+</h2>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-hide">
        {scanSettings && <ScanSettingSidebar />}
        {homeSettings && <HomeSettingSidebar />}
        {settings && <SettingSidebar />}
      </div>

     
      <div className="mt-auto pt-4 border-t flex justify-between items-center px-4">
  {/* Settings Button */}
  <Link
    to="/settings/about" // or your default settings route
    className="flex items-center text-gray-700 hover:text-black"
  >
    <Settings className="w-5 h-5 mr-2" />
    <span>Settings</span>
  </Link>

  {/* Logout Icon Button */}
  <button
    onClick={handleLogout}
    className="flex items-center text-red-600 hover:text-red-800"
  >
    <LogOut className="w-5 h-5 mr-2" />
    <span>Logout</span>
  </button>
</div>

    </div>
  );
};




export default Sidebar;