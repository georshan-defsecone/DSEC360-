import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { ChevronDown, ChevronUp } from "lucide-react";

const SidebarSection = ({
  title,
  links,
}: {
  title: string;
  links: { to: string; label: string; icon?: JSX.Element }[];
}) => {
  const [isOpen, setIsOpen] = useState(true);
  const location = useLocation();

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
        <div className="space-y-2 mt-1">
          {links.map(({ to, label, icon }) => {
            const isActive = location.pathname === to
            return (
              <Link to={to} key={to}>
                <button className={`flex items-center gap-2 w-full text-left px-4 py-2 rounded ${isActive ? "bg-black text-white" : "hover:bg-black hover:text-white"}`}>
                  {icon && icon}{label}
                </button>
              </Link>
            )
        })}
        </div>
      )}
    </div>
  );
};

export default SidebarSection;