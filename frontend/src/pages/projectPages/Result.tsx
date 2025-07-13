import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import api from "../api";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from "@/components/ui/dropdown-menu";
import { MoreVertical } from "lucide-react";
import ScanPieChart from "@/components/ScanPieChart";

export default function ProjectScans() {
  const [scans, setScans] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [scanTypeStats, setScanTypeStats] = useState<Record<string, number>>({});
  const navigate = useNavigate();

  useEffect(() => {
    const fetchScans = async () => {
      try {
        const response = await api.get("scans/user", {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
        });
        setScans(response.data);

        const typeStats: Record<string, number> = {};
        for (const scan of response.data) {
          const type = scan.scan_type || "Unknown";
          typeStats[type] = (typeStats[type] || 0) + 1;
        }
        setScanTypeStats(typeStats);
      } catch (err) {
        console.error("Error fetching scans:", err);
      }
    };

    fetchScans();
  }, []);

  const filteredScans = scans.filter((s) =>
    `${s.scan_name} ${s.scan_author} ${s.scan_status}`
      .toLowerCase()
      .includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64 pt-20 bg-gray-50">
        <Header title="Results" />

        <div className="w-full px-6 mt-4">
          <div className="flex">
            {/* Left - Scan Table */}
            <Card className="w-[65%] mt-7 shadow-lg border border-gray-200 bg-white rounded-none">
              <CardContent className="p-5">
                <div className="flex justify-between items-center mb-2">
                  <h2 className="text-xl font-semibold text-gray-800">
                    Scan List
                  </h2>
                  <input
                    type="text"
                    placeholder="Search..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                  />
                </div>

                <div className="border-b border-gray-300 mb-4" />

                <div className="overflow-y-auto h-[400px]">
                  <table className="table-fixed w-full text-sm border-collapse">
                    <thead className="sticky top-0 z-10 bg-gray-100 text-gray-700 border-b border-gray-400">
                      <tr>
                        <th className="w-[35%] text-left px-4 py-2">Scan Name</th>
                        <th className="w-[25%] text-left px-4 py-2">Author</th>
                        <th className="w-[20%] text-left px-4 py-2">Status</th>
                        <th className="w-[10%] text-left px-4 py-2"></th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredScans.length === 0 ? (
                        <tr>
                          <td colSpan={4} className="text-center py-4">
                            No matching scans found.
                          </td>
                        </tr>
                      ) : (
                        filteredScans.map((scan, i) => (
                          <tr
                            key={i}
                            className={`cursor-pointer hover:bg-gray-100 border-b ${
                              i % 2 === 0 ? "bg-white" : "bg-gray-50"
                            }`}
                            onClick={() =>
                              navigate(`/project/${scan.project}/scan/${scan.scan_name}`)
                            }
                          >
                            <td className="py-3 px-4 font-medium">{scan.scan_name}</td>
                            <td className="py-3 px-4">{scan.scan_author}</td>
                            <td className="py-3 px-4">{scan.scan_status}</td>
                            <td
                              className="py-3 px-4"
                              onClick={(e) => e.stopPropagation()}
                            >
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <button className="p-1 rounded hover:bg-gray-200">
                                    <MoreVertical size={18} />
                                  </button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem
                                    onClick={() =>
                                      navigate(`/project/${scan.project}/scan/${scan.scan_name}`)
                                    }
                                  >
                                    View
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() => console.log("Download scan")}
                                  >
                                    Download
                                  </DropdownMenuItem>
                                </DropdownMenuContent>
                              </DropdownMenu>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>

            {/* Divider */}
            <div className="w-[1px] bg-gray-300 mt-7 mx-4 ml-12"></div>

            {/* Right - Pie Chart */}
            <Card className="w-[15%] min-w-[320px] h-[500px] mt-7 shadow-lg border border-gray-200 bg-white rounded-none flex items-center justify-center">
              <CardContent className="flex items-center justify-center w-full h-full">
                <ScanPieChart data={scanTypeStats} />
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
