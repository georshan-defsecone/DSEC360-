import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import api from "../api";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { MoreVertical, Save, X } from "lucide-react";
import ScanPieChart from "@/components/ScanPieChart";

const AllProjects = () => {
  const [projects, setProjects] = useState([]);
  const [editingProjectId, setEditingProjectId] = useState(null);
  const [editName, setEditName] = useState("");
  const [editAuthor, setEditAuthor] = useState("");
  const [scanStats, setScanStats] = useState({});
  const [scanCounts, setScanCounts] = useState({});
  const [searchTerm, setSearchTerm] = useState("");
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedProjectForDelete, setSelectedProjectForDelete] = useState(null);

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
        console.error(`Failed to fetch scans for project ${project.project_id}:`, err);
      }
    }

    setScanStats(scanTypeCounts);
    setScanCounts(counts);
  };

  const moveToTrash = async () => {
    if (!selectedProjectForDelete) return;
    try {
      await api.put(
        `project/trash/${selectedProjectForDelete.project_id}/`,
        { trash: true },
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
        }
      );
      fetchProjects();
      setShowDeleteModal(false);
      setSelectedProjectForDelete(null);
    } catch (error) {
      console.error("Error moving project to trash:", error);
    }
  };

  const startEditing = (project) => {
    setEditingProjectId(project.project_id);
    setEditName(project.project_name);
    setEditAuthor(project.project_author);
  };

  const cancelEditing = () => {
    setEditingProjectId(null);
    setEditName("");
    setEditAuthor("");
  };

  const saveEdit = async (projectId) => {
    try {
      await api.put(
        `project/update/${projectId}/`,
        {
          project_name: editName,
          project_author: editAuthor,
        },
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
        }
      );
      setEditingProjectId(null);
      fetchProjects();
    } catch (error) {
      console.error("Error saving project:", error);
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
    <div className="flex h-screen text-black relative">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64 pt-20 bg-gray-50">
        <Header title="All Projects" />

        <div className="w-full px-6 mt-4">
          <div className="flex gap-6">
            <Card className="flex-1 mt-7 w-[20rem] shadow-lg border border-gray-200 bg-white rounded-none">
              <CardContent className="p-5">
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

                <div className="border-b-1 border-gray-800 mb-4" />

                <div className="relative">
                  <div className="overflow-y-auto h-[400px]">
                    <table className="table-fixed w-full text-sm border-collapse">
                      <thead className="sticky top-0 z-10 bg-gray-200 text-gray-700 border-b border-gray-400">
                        <tr>
                          <th className="w-[35%] text-left px-4 py-2">Project Name</th>
                          <th className="w-[25%] text-left px-4 py-2">Author</th>
                          <th className="w-[20%] text-left px-4 py-2">Scans</th>
                          <th className="w-[10%] text-left px-4 py-2"></th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredProjects.length === 0 ? (
                          <tr>
                            <td colSpan={4} className="text-center py-4">
                              No matching projects found.
                            </td>
                          </tr>
                        ) : (
                          filteredProjects.map((pro, idx) => {
                            const isEditing = editingProjectId === pro.project_id;
                            return (
                              <tr
                                key={pro.project_id}
                                className={`cursor-pointer hover:bg-gray-100 border-b border-gray-100 ${
                                  idx % 2 === 0 ? "bg-white" : "bg-gray-50"
                                }`}
                                onClick={() =>
                                  !isEditing && navigate(`/project/${pro.project_id}`)
                                }
                              >
                                <td className="py-3 px-4 font-medium border-none">
                                  {isEditing ? (
                                    <Input
                                      value={editName}
                                      onChange={(e) => setEditName(e.target.value)}
                                      className="text-sm"
                                    />
                                  ) : (
                                    pro.project_name
                                  )}
                                </td>
                                <td className="py-3 px-4 border-none">
                                  {isEditing ? (
                                    <Input
                                      value={editAuthor}
                                      onChange={(e) => setEditAuthor(e.target.value)}
                                      className="text-sm"
                                    />
                                  ) : (
                                    pro.project_author
                                  )}
                                </td>
                                <td className="py-3 px-4 border-none">
                                  {scanCounts[pro.project_id] || 0}
                                </td>
                                <td
                                  className="py-3 px-4 border-none"
                                  onClick={(e) => e.stopPropagation()}
                                >
                                  <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                      <button className="p-1 rounded hover:bg-gray-200">
                                        <MoreVertical size={18} />
                                      </button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                      {isEditing ? (
                                        <>
                                          <DropdownMenuItem
                                            onClick={() => saveEdit(pro.project_id)}
                                            className="text-green-600"
                                          >
                                            <Save size={14} className="mr-2" />
                                            Save
                                          </DropdownMenuItem>
                                          <DropdownMenuItem
                                            onClick={cancelEditing}
                                            className="text-red-500"
                                          >
                                            <X size={14} className="mr-2" />
                                            Cancel
                                          </DropdownMenuItem>
                                        </>
                                      ) : (
                                        <>
                                          <DropdownMenuItem
                                            onClick={() => startEditing(pro)}
                                          >
                                            Edit
                                          </DropdownMenuItem>
                                          <DropdownMenuItem
                                            onClick={() => {
                                              setSelectedProjectForDelete(pro);
                                              setShowDeleteModal(true);
                                            }}
                                            className="text-red-600"
                                          >
                                            Delete
                                          </DropdownMenuItem>
                                          <DropdownMenuItem
                                            onClick={() => console.log("Download")}
                                          >
                                            Download
                                          </DropdownMenuItem>
                                        </>
                                      )}
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
                </div>
              </CardContent>
            </Card>

            <div className="w-[1px] bg-gray-300 mt-7 self-stretch" />

            <Card className="w-[20rem] h-[550px] mt-7 shadow-lg border border-gray-200 bg-white rounded-none flex items-center justify-center">
              <CardContent className="flex items-center justify-center w-full h-full">
                <ScanPieChart data={scanStats} />
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* ✅ Custom Delete Modal without background overlay */}
      {showDeleteModal && (
        <div className="absolute top-0 left-0 right-0 bottom-0 flex items-center justify-center z-50">
          <div className="bg-white rounded-md shadow-xl p-6 w-[400px] border border-gray-300">
            <h2 className="text-lg font-semibold mb-2">Are you sure?</h2>
            <p className="text-sm text-gray-600 mb-6">
              This will move the project to trash.
            </p>
            <div className="flex justify-end gap-4">
              <Button variant="outline" onClick={() => setShowDeleteModal(false)}>
                Cancel
              </Button>
              <Button variant="destructive" onClick={moveToTrash}>
                Move to Trash
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AllProjects;
