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
  LogOut,
} from "lucide-react";
import { Link, useLocation } from "react-router-dom";
import SidebarSection from "@/components/SidebarSection";
import logo from "@/assets/logo.png";
import "@/styles/sidebar.css";
import { jwtDecode } from "jwt-decode";
import { useEffect, useState } from "react";
import { Button } from "./ui/button";

type SidebarProps = {
  scanSettings: boolean;
  homeSettings: boolean;
  settings: boolean;
};

//scan sidebar
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

      <SidebarSection
      title="Asset Discovery"
      links={[{to: "/scan/ad/windows", label: "Windows Domain Scan", icon:<PanelTop size={16} />,}]}
      />
    </nav>
  );
};

//Settings sidebar

const SettingSidebar = () => {
  const location = useLocation();
  const currentPath = location.pathname;

  const navItems = [
    { label: "About", path: "/settings/about" },
    { label: "My Accounts", path: "/settings/myaccounts" },
    { label: "Advance", path: "/settings/advance" },
    { label: "Proxy Server", path: "/settings/proxyserver" },
    { label: "SMTP Server", path: "/settings/smtp" },
    { label: "LDAP", path: "/settings/ldap" },
    { label: "Users", path: "/settings/users" },
  ];

  return (
    <nav className="space-y-2">
      {navItems.map((item) => {
        const isActive = currentPath === item.path;
        return (
          <Link to={item.path} key={item.path}>
            <button
              className={`block w-full text-left px-4 py-2 rounded font-medium cursor-pointer ${
                isActive
                  ? "bg-black text-white"
                  : "hover:bg-gray-400 hover:text-white"
              }`}
            >
              {item.label}
            </button>
          </Link>
        );
      })}
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
      <SidebarSection
        collapsible={false}
        links={[
          
          ...(isAdmin
            ? [
                {
                  to: "/dashboard/allprojects",
                  label: "Projects",
                },
              ]
            : []),
          {
            to: "/dashboard/results",
            label: "Scans",
          },
          {
            to: "/dashboard/trash",
            label: "Trash",
          },
        ]}
      />
    </>
  );
};

//overall side bar setting decide which to display

const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {
  return (
    <div className="fixed top-0 left-0 h-screen w-64 flex flex-col p-6 justify-between  z-10 bg-neutral-100 border-r border-r-neutral-200">
      <div>
        <div className="mb-6">
          <a href="/" className="inline-flex items-center gap-4">
          <img src={logo} alt="Logo" className="w-10" />
          <h2 className="text-2xl font-bold">DES360+</h2>
          </a>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-hide pt-4">
        {scanSettings && <ScanSettingSidebar />}
        {homeSettings && <HomeSettingSidebar />}
        {settings && <SettingSidebar />}
      </div>

      <div className="mt-4">
        <Link to="/settings/about">
  <Button className="flex items-center px-4 py-2 bg-black text-white rounded  cursor-pointer">
    <Settings className="w-5 h-5 " />
  </Button>
</Link>
      </div>
    </div>
  );
};

export default Sidebar;
