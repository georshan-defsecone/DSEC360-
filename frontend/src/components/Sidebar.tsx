import { Settings } from "lucide-react";
import logo from "@/assets/logo.png";
import "@/styles/sidebar.css"

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
    <div className="flex-1 overflow-y-auto scrollbar-hide p-3 space-y-2">
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        My Projects
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        All Projects
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Results
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
        Trash
      </button>
    </div>
  );
};




const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {
  return (
    <div className="h-screen flex flex-col w-65 p-6 justify-between">

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