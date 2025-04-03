import React from "react";
import {
  ShieldCheck,
  Settings,
  Server,
  Terminal,
  MonitorSmartphone,
  Network,
} from "lucide-react"; // Importing icons

const SidebarSection = ({ title, items }: { title: string; items: any[] }) => {
  return (
    <div>
      {/* Section Header */}
      <h3 className="text-gray-400 uppercase text-xs font-semibold mb-2">
        {title}
      </h3>

      {/* List Items */}
      <ul className="space-y-2">
        {items.map((item, index) => (
          <li
            key={index}
            className="flex items-center space-x-2 px-3 py-1 rounded-md text-sm hover:bg-gray-700 cursor-pointer transition"
          >
            <item.icon size={18} />
            <span>{item.label}</span>
          </li>
        ))}
      </ul>
    </div>
  );
};

const Sidebar = () => {
  return (
    <aside className="h-screen w-64 bg-gray-900 text-white p-4 flex flex-col fixed top-20 left-0 shadow-lg">
      <h2 className="text-lg font-bold mb-4 text-white">Security Dashboard</h2>

      <nav className="space-y-4">
        <SidebarSection
          title="Vulnerability Management"
          items={[
            { icon: ShieldCheck, label: "Asset Discovery" },
            { icon: Server, label: "Ports & Service Enumeration" },
            { icon: Terminal, label: "Default Scan (Black Box)" },
            { icon: MonitorSmartphone, label: "Advanced Scan (White Box)" },
            { icon: Settings, label: "Remediation Status" },
          ]}
        />

        <SidebarSection
          title="Configuration Audit"
          items={[
            { icon: Server, label: "Windows" },
            { icon: Terminal, label: "Linux" },
            { icon: Network, label: "Network/Security Devices" },
          ]}
        />

        <SidebarSection
          title="Compromise Assessment"
          items={[
            { icon: Server, label: "Windows" },
            { icon: Terminal, label: "Linux" },
          ]}
        />
      </nav>
    </aside>
  );
};

export default Sidebar;
