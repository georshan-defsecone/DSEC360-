import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import api from "../api";
import { Card, CardContent } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import { MoreVertical } from "lucide-react";
import ScanPieChart from "@/components/ScanPieChart";

export default function ProjectScans() {
  const [scans, setScans] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [scanTypeStats, setScanTypeStats] = useState<Record<string, number>>(
    {}
  );
  const [showDeletePrompt, setShowDeletePrompt] = useState(false);
  const [selectedScan, setSelectedScan] = useState<any>(null);
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

  const deleteScan = async () => {
    if (!selectedScan) return;

    try {
      await api.put(
        `scans/${selectedScan.scan_id}/trash/`,
        { trash: true },
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
        }
      );

      setScans((prev) =>
        prev.filter((s) => s.scan_id !== selectedScan.scan_id)
      );
      setShowDeletePrompt(false);
      setSelectedScan(null);
    } catch (err) {
      console.error("Failed to delete scan", err);
    }
  };

  const downloadScan = async (project: string, scanName: string) => {
    try {
      const response = await api.get(
        `download/project/${project}/scan/${scanName}/`,
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
          responseType: "blob",
        }
      );

      const blob = new Blob([response.data], { type: "application/zip" });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `${project}_${scanName}_excels.zip`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch (error: any) {
      console.error("Error downloading scan:", error);
      alert(
        "Download failed: " + (error?.response?.data?.error || "Unknown error")
      );
    }
  };

  const filteredScans = scans.filter((s) =>
    `${s.scan_name} ${s.scan_author} ${s.scan_status}`
      .toLowerCase()
      .includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex h-screen text-black relative">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64 pt-20 bg-gray-50">
        <Header title="Results" />

        <div className="w-full px-6 mt-4">
          <div className="flex gap-8">
            {/* Left - Scan Table */}
            <Card className="flex-1 mt-7 shadow-lg border border-gray-200 bg-white rounded-none">
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
                    <thead className="sticky top-0 z-10 bg-gray-200 text-gray-700 border-b border-gray-400">
                      <tr>
                        <th className="w-[35%] text-left px-4 py-2">
                          Scan Name
                        </th>
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
                        filteredScans.map((scan, i) => {
                          // Check if scan_result exists and is not an empty object
                          const hasResults =
                            scan.scan_result &&
                            Object.keys(scan.scan_result).length > 0;

                          return (
                            <tr
                              key={i}
                              className={`border-b ${
                                i % 2 === 0 ? "bg-white" : "bg-gray-50"
                              } ${
                                hasResults
                                  ? "cursor-pointer hover:bg-gray-100"
                                  : "opacity-60 cursor-not-allowed"
                              }`}
                              onClick={() => {
                                if (hasResults) {
                                  navigate(
                                    `/scan/scanresult/${encodeURIComponent(
                                      scan.project_name
                                    )}/${encodeURIComponent(scan.scan_name)}`
                                  );
                                }
                              }}
                            >
                              <td className="py-3 px-4 font-medium">
                                {scan.scan_name}
                              </td>
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
                                      className="text-red-600"
                                      onClick={() => {
                                        setSelectedScan(scan);
                                        setShowDeletePrompt(true);
                                      }}
                                    >
                                      Delete
                                    </DropdownMenuItem>
                                    <DropdownMenuItem
                                      disabled={!hasResults} // Disable download if no results
                                      onClick={() => {
                                        if (hasResults) {
                                            downloadScan(
                                              scan.project_name,
                                              scan.scan_name
                                            );
                                        }
                                      }}
                                    >
                                      Download
                                    </DropdownMenuItem>
                                  </DropdownMenuContent>
                                </DropdownMenu>
                              </td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>

            {/* Vertical Divider */}
            <div className="w-[1px] bg-gray-300 mt-7" />

            {/* Right - Pie Chart */}
            <Card className="w-[20rem] h-[550px] mt-7 shadow-lg border border-gray-200 bg-white rounded-none flex items-center justify-center">
              <CardContent className="flex items-center justify-center w-full h-full">
                <ScanPieChart data={scanTypeStats} />
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeletePrompt && (
        <div className="absolute top-0 left-0 right-0 bottom-0 flex items-center justify-center z-50">
          <div className="bg-white rounded-md shadow-xl p-6 w-[400px] border border-gray-300">
            <h2 className="text-lg font-semibold mb-2">Are you sure?</h2>
            <p className="text-sm text-gray-600 mb-6">
              This will move scan{" "}
              <strong className="text-red-600">
                {selectedScan?.scan_name}
              </strong>{" "}
              to trash.
            </p>
            <div className="flex justify-end gap-4">
              <Button
                variant="outline"
                onClick={() => setShowDeletePrompt(false)}
              >
                Cancel
              </Button>
              <Button variant="destructive" onClick={deleteScan}>
                Confirm Delete
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}