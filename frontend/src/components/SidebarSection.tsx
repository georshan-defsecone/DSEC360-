import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { ChevronDown, ChevronUp } from "lucide-react";

const SidebarSection = ({
  title,
  links,
  collapsible = true,
}: {
  title?: string;
  links: { to: string; label: string; icon?: JSX.Element }[];
  collapsible?: boolean;
}) => {
  const [isOpen, setIsOpen] = useState(true);
  const location = useLocation();

  return (
    <nav>
      {title && (
        <div className="flex items-center justify-between w-full px-4 py-3 font-bold text-sm tracking-wide uppercase">
          <span>{title}</span>
          {collapsible && (
            <button
              onClick={() => setIsOpen(!isOpen)}
              className="hover:text-blue-600 transition"
            >
              {isOpen ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
            </button>
          )}
        </div>
      )}

      {(isOpen || !collapsible) && (
        <div className="space-y-2 mt-1">
          {links.map(({ to, label, icon }) => {
            const isActive = location.pathname === to;
            return (
              <Link to={to} key={to}>
                <button
                  className={`flex items-center gap-2 w-full text-left px-4 py-2 rounded font-medium transition cursor-pointer ${
                    isActive
                      ? "bg-black text-white"
                      : "text-gray-700 hover:bg-gray-300 hover:text-black"
                  }`}
                >
                  {icon && icon}
                  {label}
                </button>
              </Link>
            );
          })}
        </div>
      )}
    </nav>
  );
};

export default SidebarSection;
