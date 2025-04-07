import { Settings } from "lucide-react";
import logo from "@/assets/logo.png";

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
        Networks Devices
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

const SettingSidebar = () => {
  return (<>
    <nav className="space-y-2">
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        About
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Advance
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Proxy Server
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        SMTP Server
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        LDAP
      </button>
      </nav>
      <nav className="mt-7">
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        My accounts
      </button>
      <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
        Users
      </button>
    </nav> </>
  );
};

const HomeSettingSidebar= ()=>{
  return(<>
  <div className="flex-1 overflow-y-auto scrollbar-hide p-3 border-b-2 border-b-stone-200 mb-2">
      <nav className="space-y-2">
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
          My Projects
        </button>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
          All Projects
        </button>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
          Results
        </button>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-100 font-medium">
          Trash
        </button>
      </nav>
  </div>
  <div>
    <button className="flex items-center justify-end-safe px-4  rounded hover:bg-slate-100">
      <Settings className="w-5 h-8" />
    </button>
  </div>
</>)
}



const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {

  return(
    <>
      <div className="h-screen flex flex-col  bg-white w-65 p-6">
        <div>
          <div className="flex items-center mb-6">
            <img src={logo} alt="Logo" className="w-10" />
            <h2 className="text-2xl font-bold ml-3">DES360+</h2>
          </div>
        </div>
        {scanSettings && <ScanSettingSidebar></ScanSettingSidebar>}
        {homeSettings && <HomeSettingSidebar></HomeSettingSidebar>}
        {settings && <SettingSidebar></SettingSidebar>}
        </div>
    </>
  )
}


export default Sidebar;