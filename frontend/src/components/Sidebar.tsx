import {
  ChevronDown,
  ChevronUp,
  Shield,
  Server,
  Database,
  Cloud,
  Box,
  SatelliteDish,
  PanelTop,
  TerminalSquare,
  Settings,
  LogOut
} from "lucide-react";
import { Link } from "react-router-dom";
import logo from "@/assets/logo.png";
import "@/styles/sidebar.css";
import { jwtDecode } from "jwt-decode";
import { useEffect, useState } from "react";

type SidebarProps = {
  scanSettings: boolean;
  homeSettings: boolean;
  settings: boolean;
};

//scan sidebar

const SidebarSection = ({
  title,
  links,
}: {
  title: string;
  links: { to: string; label: string; icon: JSX.Element }[];
}) => {
  const [isOpen, setIsOpen] = useState(true);

  return (
    <div>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center justify-between w-full text-left px-4 py-3 font-bold text-sm tracking-wide uppercase"
      >
        <span>{title}</span>
        {isOpen ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
      </button>
      {isOpen && (
        <div className="space-y-2 mt-1 font-semibold">
          {links.map(({ to, label, icon }) => (
            <Link to={to} key={to}>
              <button className="flex items-center gap-2 w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium text-sm">
                {icon} {label}
              </button>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
};

const ScanSettingSidebar = () => {
  return (
    <nav className="space-y-2">
      <SidebarSection
        title="Configuration Audit"
        links={[
          {
            to: "/scan/configaudit/windows",
            label: "Windows",
            icon: <PanelTop size={16} />,
          },
          {
            to: "/scan/configaudit/linux",
            label: "Linux",
            icon: <TerminalSquare size={16} />,
          },
          {
            to: "/scan/configaudit/firewall",
            label: "Firewall",
            icon: <Shield size={16} />,
          },
          {
            to: "/scan/configaudit/WAservers",
            label: "Web & App Servers",
            icon: <Server size={16} />,
          },
          {
            to: "/scan/configaudit/networkDevices",
            label: "Network Devices",
            icon: <SatelliteDish size={16} />,
          },
          {
            to: "/scan/configaudit/databases",
            label: "Database",
            icon: <Database size={16} />,
          },
          {
            to: "/scan/configaudit/cloud",
            label: "Cloud",
            icon: <Cloud size={16} />,
          },
          {
            to: "/scan/configaudit/containersAndOrchestration",
            label: "Containers & Orchestration",
            icon: <Box size={16} />,
          },
        ]}
      />

      <SidebarSection
        title="Compromise Assessment"
        links={[
          {
            to: "/scan/ioc/windows",
            label: "Windows",
            icon: <PanelTop size={16} />,
          },
          {
            to: "/scan/ioc/linux",
            label: "Linux",
            icon: <TerminalSquare size={16} />,
          },
        ]}
      />
    </nav>
  );
};

//Settings sidebar

const SettingSidebar = () => {
  return (
    <nav className="space-y-2">
      <Link to={"/settings/about"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          About
        </button>
      </Link>
      <Link to={"/settings/myaccounts"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          My Accounts
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
      <Link to={"/settings/users"}>
        <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
          Users
        </button>
      </Link>
    </nav>
  );
};

const handleLogout = () => {
  localStorage.removeItem("access");
  localStorage.removeItem("refresh");
  localStorage.removeItem("accessToken");
  localStorage.removeItem("refreshToken");
  window.location.href = "/login";
};

//Home sidebar

const HomeSettingSidebar = () => {
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    const access = localStorage.getItem("access");
    if (access) {
      try {
        const decoded: any = jwtDecode(access);
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

//overall side bar setting decide which to display

const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {
  return (
    <div className="fixed top-0 left-0 h-screen w-64 flex flex-col p-6 justify-between  z-10 bg-white ">
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
        <Link to={"/settings/about"}>
          <Settings className="w-5 h-5 mr-2" />
          </Link>
        </button>
         
      </div>
    </div>
  );
};

export default Sidebar;
