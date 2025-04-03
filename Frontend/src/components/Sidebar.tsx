import { Link } from "react-router-dom";
import { SheetContent } from "@/components/ui/sheet"; 
import logo from "../assets/logo.png";

const Sidebar = () => {
    return (
        <div className="w-70 h-screen bg-[#d3d3d3] shadow-lg p-4 fixed left-0 text-left mt-4">
            <nav className="mt-6">
                <div>
                    <h1 className="block p-2  font-bold text-lg underline underline-offset-8  decoration-1">
                        Vulnerability Management
                    </h1>
                    <div className="pl-2 text-sm text-gray-700">
                        <Link to="/asset-discovery" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">Asset Discovery</Link>

                        <Link to="/ports-service-enumeration" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">Ports and Service Enumeration</Link>

                        <Link to="/default-scan" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">Default Scan (Black Box)</Link>

                        <Link to="/advanced-scan" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">Advanced Scan (White Box)</Link>

                        <Link to="/remediation-status" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">Remediation Status</Link>
                    </div>
                </div>

                <div>
                    <h1 className="block p-2 font-bold mt-4 text-lg underline underline-offset-8  decoration-1">
                        Configuration Audit
                    </h1>
                  
                    <div className="pl-2 text-sm text-gray-900">
                        <Link to="/windows" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">
                            Windows
                        </Link>
                        <Link to="/linux" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">
                            Linux
                        </Link>
                        <Link to="/network" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">
                            Network/Security Devices
                        </Link>
                    </div>

                </div>


                <div>
                    <h1 className="block p-2 font-bold mt-4 text-lg underline underline-offset-8  decoration-1">
                        Compromise Assessment
                    </h1>
                    <div className="pl-2 text-sm text-gray-700">
                        <Link to="/windows" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base">Windows</Link>
                        <Link to="/linux" className="block p-1 hover:bg-gray-200 rounded-lg font-medium mt-2 text-gray-800 text-base"> Linux</Link>
                    
                    </div>
                    
                </div>
                
                
            </nav>
        </div>
    );
};

export default Sidebar;
