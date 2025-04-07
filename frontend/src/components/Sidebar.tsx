import { Settings } from "lucide-react";

type SidebarProps = {
  scanSettings: boolean;
  homeSettings: boolean;
  settings: boolean;
};

const HomeSettings = () => {
  return (
    <nav className="space-y-5">
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
        My Projects
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
        All Projects
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
        Results
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
        Trash
      </button>
    </nav>
  );
};

const ScanSettings = () => {
  return (
    <nav className="space-y-5">
      <h1 className="block w-full text-left px-4 py-2 font-semibold">
        Configuration Audit
      </h1>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Windows
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Linux
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Firewall
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Web Servers & Application Servers
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Network Devices
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Database
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Cloud
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Containers & Orchestration
      </button>
      <h1 className="block w-full text-left px-4 py-2 font-semibold">
        Compromise Assessment
      </h1>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Windows
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Linux
      </button>
    </nav>
  );
};

const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {
  return (
    <div className="w-60 h-screen flex flex-col justify-between bg-white border-r">
     
      <div className="p-6">
        <div className="flex items-center mb-6">
          <img src="logo.png" alt="Logo" className="w-10" />
          <h2 className="text-2xl font-bold ml-3">DES360+</h2>
        </div>

        {scanSettings ? <ScanSettings /> : <HomeSettings />}
      </div>

      <div className="px-4 py-4 cursor-pointer flex items-center gap-2">
        <Settings className="w-5 h-5" />
      </div>
    </div>
  );
};


export default Sidebar;
