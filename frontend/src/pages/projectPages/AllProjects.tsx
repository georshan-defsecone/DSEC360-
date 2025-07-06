import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import api from "../api";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreVertical } from "lucide-react";
import ScanPieChart from "@/components/ScanPieChart";

const AllProjects = () => {
  const [projects, setProjects] = useState([]);
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  const [scanStats, setScanStats] = useState({});
  const [scanCounts, setScanCounts] = useState({});
  const [searchTerm, setSearchTerm] = useState("");
  const navigate = useNavigate();

  const fetchProjects = async () => {
    try {
      const response = await api.get("all-projects/", {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("access")}`,
        },
      });
      setProjects(response.data);
      fetchAllScanData(response.data);
    } catch (error) {
      console.error("Error fetching all projects:", error);
    }
  };

  const fetchAllScanData = async (projectList) => {
    const scanTypeCounts = {};
    const counts = {};

    for (const project of projectList) {
      try {
        const res = await api.get(`scans/project/${project.project_id}/`, {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
        });

        const scans = res.data;
        counts[project.project_id] = scans.length;

        for (const scan of scans) {
          const type = scan.scan_type;
          scanTypeCounts[type] = (scanTypeCounts[type] || 0) + 1;
        }
      } catch (err) {
        console.error(
          `Failed to fetch scans for project ${project.project_id}:`,
          err
        );
      }
    }

    setScanStats(scanTypeCounts);
    setScanCounts(counts);
  };

  const moveToTrash = async (projectId) => {
    try {
      await api.put(
        `project/trash/${projectId}/`,
        { trash: true },
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
        }
      );
      fetchProjects();
    } catch (error) {
      console.error("Error moving project to trash:", error);
    }
  };

  useEffect(() => {
    fetchProjects();
  }, []);

  const filteredProjects = projects.filter((pro) =>
    `${pro.project_name} ${pro.project_author}`
      .toLowerCase()
      .includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64 pt-20 bg-gray-50">
        <Header title="All Projects" />

        <div className="w-full px-6 mt-4">
          <div className="flex">
            {/* Left - Project Table */}
            <Card className="w-[65%] mt-7 shadow-lg border border-gray-200 bg-white rounded-none">
              <CardContent className="p-5">
                {/* Header row with title and search */}
                <div className="flex justify-between items-center mb-2">
                  <h2 className="text-xl font-semibold text-gray-800">
                    Project List
                  </h2>
                  <input
                    type="text"
                    placeholder="Search..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                  />
                </div>

                {/* Dark Divider Line */}
                <div className="border-b-1 border-gray-800 mb-4" />

                <div className="relative">
                  <Table className="table-auto w-full text-sm">
                    <TableHeader>
                      <TableRow className="sticky top-0 z-10 bg-gray-100 text-gray-700 border-b border-gray-400">
                        <TableHead className="w-[35%] text-left">
                          Project Name
                        </TableHead>
                        <TableHead className="w-[25%] text-left">
                          Author
                        </TableHead>
                        <TableHead className="w-[20%] text-left">
                          Scans
                        </TableHead>
                        <TableHead className="w-[10%] text-left"></TableHead>
                      </TableRow>
                    </TableHeader>
                  </Table>

                  <div className="h-[410px] overflow-y-auto">
                    <Table className="table-auto w-full text-sm">
                      <TableBody>
                        {filteredProjects.length === 0 ? (
                          <TableRow>
                            <TableCell
                              colSpan={4}
                              className="text-center py-4"
                            >
                              No matching projects found.
                            </TableCell>
                          </TableRow>
                        ) : (
                          filteredProjects.map((pro, idx) => (
                            <TableRow
                              key={pro.project_id}
                              className={`cursor-pointer hover:bg-gray-100 border-b border-gray-100 ${
                                idx % 2 === 0 ? "bg-white" : "bg-gray-50"
                              }`}
                              onClick={() =>
                                navigate(`/project/${pro.project_id}`)
                              }
                            >
                              <TableCell className="py-3 font-medium border-none">
                                {pro.project_name}
                              </TableCell>
                              <TableCell className="py-3 border-none">
                                {pro.project_author}
                              </TableCell>
                              <TableCell className="py-3 border-none">
                                {scanCounts[pro.project_id] || 0}
                              </TableCell>
                              <TableCell
                                className="py-3 border-none"
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
                                      onClick={() => console.log("Update")}
                                    >
                                      Update
                                    </DropdownMenuItem>
                                    <AlertDialog>
                                      <AlertDialogTrigger asChild>
                                        <DropdownMenuItem
                                          onSelect={(e) => {
                                            e.preventDefault();
                                            setSelectedProjectId(
                                              pro.project_id
                                            );
                                          }}
                                        >
                                          Delete
                                        </DropdownMenuItem>
                                      </AlertDialogTrigger>
                                      <AlertDialogContent>
                                        <AlertDialogHeader>
                                          <AlertDialogTitle>
                                            Are you sure?
                                          </AlertDialogTitle>
                                          <AlertDialogDescription>
                                            This will move the project to
                                            trash. You can restore it later if
                                            needed.
                                          </AlertDialogDescription>
                                        </AlertDialogHeader>
                                        <AlertDialogFooter>
                                          <AlertDialogCancel>
                                            Cancel
                                          </AlertDialogCancel>
                                          <AlertDialogAction
                                            onClick={() => {
                                              if (selectedProjectId)
                                                moveToTrash(selectedProjectId);
                                            }}
                                          >
                                            Move to Trash
                                          </AlertDialogAction>
                                        </AlertDialogFooter>
                                      </AlertDialogContent>
                                    </AlertDialog>
                                    <DropdownMenuItem
                                      onClick={() => console.log("Download")}
                                    >
                                      Download
                                    </DropdownMenuItem>
                                  </DropdownMenuContent>
                                </DropdownMenu>
                              </TableCell>
                            </TableRow>
                          ))
                        )}
                      </TableBody>
                    </Table>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Vertical Divider */}
            <div className="w-[1px] bg-gray-300 mt-7 mx-4 ml-12"></div>

            {/* Right - Pie Chart (enlarged) */}
            <div className="w-[15%] min-w-[320px] h-[500px] ml-6 flex items-center justify-center ">
              <ScanPieChart data={scanStats} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AllProjects;
