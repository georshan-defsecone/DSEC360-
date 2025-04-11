import { Settings, LogOut } from "lucide-react";
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

const Sidebar = ({ scanSettings, homeSettings, settings }: SidebarProps) => {
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

  const handleLogout = () => {
    localStorage.removeItem("access");
    localStorage.removeItem("refresh");
    localStorage.removeItem("accessToken");
    localStorage.removeItem("refreshToken");
    window.location.href = "/login";
  };

  return (
    <div className="fixed top-0 left-0 h-screen w-64 flex flex-col p-6 justify-between z-10 bg-white">
      {/* Logo */}
      <div>
        <Link to="/" className="flex items-center mb-6 no-underline">
          <img src={logo} alt="Logo" className="w-10" />
          <h2 className="text-2xl font-bold ml-3 text-black">DSEC360+</h2>
        </Link>
      </div>

      {/* Conditional Navigation */}
      <div className="flex-1 overflow-y-auto scrollbar-hide">
        {scanSettings && <ScanSettingSidebar />}
        {homeSettings && <HomeSettingSidebar isAdmin={isAdmin} />}
        {settings && <SettingSidebar isAdmin={isAdmin} />}
      </div>

      {/* Footer */}
      <div className="mt-auto pt-4 border-t flex justify-between items-center px-4">
        <Link to="/settings/about" className="flex items-center text-gray-700 hover:text-black">
          <Settings className="w-5 h-5 mr-2" />
        </Link>
        <button onClick={handleLogout} className="flex items-center text-red-600 hover:text-red-800">
          <LogOut className="w-5 h-5 mr-2" />
        </button>
      </div>
    </div>
  );
};

const ScanSettingSidebar = () => (
  <nav className="space-y-2">
    <h1 className="block w-full text-left px-4 py-2 font-semibold">Configuration Audit</h1>
    <Link to="/scan/windows"><SidebarButton text="Windows" /></Link>
    <Link to="/scan/linux"><SidebarButton text="Linux" /></Link>
    <SidebarButton text="Firewall" />
    <SidebarButton text="Web Servers & Application Servers" />
    <SidebarButton text="Networks Devices" />
    <SidebarButton text="Database" />
    <SidebarButton text="Cloud" />
    <SidebarButton text="Containers & Orchestration" />
    <h1 className="block w-full text-left px-4 py-2 font-semibold">Compromise Assessment</h1>
    <SidebarButton text="Windows" />
    <SidebarButton text="Linux" />
  </nav>
);

const SettingSidebar = ({ isAdmin }: { isAdmin: boolean }) => (
  <nav className="space-y-2">
    <Link to="/settings/about"><SidebarButton text="About" /></Link>
    {isAdmin && (
      <>
        <Link to="/settings/advanced"><SidebarButton text="Advance" /></Link>
        <Link to="/settings/proxyserver"><SidebarButton text="Proxy Server" /></Link>
        <Link to="/settings/smtp"><SidebarButton text="SMTP Server" /></Link>
        <Link to="/settings/ldap"><SidebarButton text="LDAP" /></Link>
      </>
    )}
    <Link to="/settings/myaccounts"><SidebarButton text="My accounts" /></Link>
    {isAdmin && (
      <Link to="/settings/users"><SidebarButton text="Users" /></Link>
    )}
  </nav>
);

const HomeSettingSidebar = ({ isAdmin }: { isAdmin: boolean }) => (
  <nav className="space-y-2">
    <Link to="/"><SidebarButton text="My Projects" /></Link>
    {isAdmin && <Link to="/dashboard/allprojects"><SidebarButton text="All Projects" /></Link>}
    <Link to="/dashboard/results"><SidebarButton text="Results" /></Link>
    <Link to="/dashboard/trash"><SidebarButton text="Trash" /></Link>
  </nav>
);

const SidebarButton = ({ text }: { text: string }) => (
  <button className="block w-full text-left px-4 py-2 rounded hover:bg-black hover:text-white font-medium">
    {text}
  </button>
);

export default Sidebar;
