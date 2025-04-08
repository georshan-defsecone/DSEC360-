import { Settings } from "lucide-react";
import logo from "@/assets/logo.png";
import "@/styles/sidebar.css"
import { Link } from "react-router-dom";

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
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Windows
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Linux
      </button>
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
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        About
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Advance
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Proxy Server
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        SMTP Server
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        LDAP
      </button>
      </nav>
      <nav className="mt-7">
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        My accounts
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Users
      </button>
    </nav> </>
  );
};  

const HomeSettingSidebar = () => {
  return (
    <>
      <nav className="space-y-2">
        <Link to={"/"}>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
            My Projects
          </button>
        </Link>

        <Link to={"/dashboard/allprojects"}>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
            All Projects
          </button>
        </Link>

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




const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {
  return (
    <div className="fixed top-0 left-0 h-screen w-64 flex flex-col p-6 justify-between  z-10 ">
      <div>
        <div className="flex items-center mb-6">
          <img src={logo} alt="Logo" className="w-10" />
          <h2 className="text-2xl font-bold ml-3">DES360+</h2>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-hide">
        {scanSettings && <ScanSettingSidebar />}
        {homeSettings && <HomeSettingSidebar />}
        {settings && <SettingSidebar />}
      </div>    

      <div className="mt-4">
        <button className="flex items-center px-4 py-2">
          <Settings className="w-5 h-5 mr-2" />
        </button>
      </div>
    </div>
  );
};




export default Sidebar;