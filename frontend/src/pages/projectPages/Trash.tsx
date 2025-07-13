import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ScrollArea } from "@/components/ui/scroll-area";
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
import { ArchiveRestore, Trash2 } from "lucide-react";
import api from "../api";

export default function Trash() {
  const [trashedProject, setTrashedProject] = useState([]);
  const [selectedProjectId, setSelectedProjectId] = useState(null);

  const fetchTrashedProject = async () => {
    try {
      const response = await api.get("projects/trash/");
      setTrashedProject(response.data);
    } catch (error) {
      console.error("Error fetching trashed project:", error);
    }
  };

  const restoreProject = async (projectId) => {
    try {
      await api.put(`project/trash/${projectId}/`, { trash: false });
      fetchTrashedProject();
    } catch (err) {
      console.error("Failed to restore project", err);
    }
  };

  const deleteProject = async (projectId) => {
    try {
      await api.delete(`project/trash/delete/${projectId}/`);
      fetchTrashedProject();
    } catch (err) {
      console.error("Failed to delete project", err);
    }
  };

  useEffect(() => {
    fetchTrashedProject();
  }, []);

  return (
    <div className="flex h-screen text-black pt-20">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64 bg-gray-50">
        <div className="flex justify-between items-center px-6">
          <Header title="Trash" />
        </div>

        <div className="w-full px-6 mt-4">
          <Card className="w-full mt-7 shadow-lg border border-gray-200 bg-white rounded-none">
            <CardContent className="p-5">
              <h2 className="text-xl font-semibold text-gray-800 mb-2">Trashed Projects</h2>
              <div className="border-b border-gray-300 mb-4" />

              <div className="overflow-y-auto max-h-[450px]">
                <Table className="table-fixed w-full text-sm border-collapse">
                  <TableHeader className="sticky top-0 z-10 bg-gray-100 text-gray-700 border-b border-gray-400">
                    <TableRow>
                      <TableHead className="w-[35%] text-left px-4 py-2">Project Name</TableHead>
                      <TableHead className="w-[25%] text-left px-4 py-2">Author</TableHead>
                      <TableHead className="w-[20%] text-left px-4 py-2">Restore</TableHead>
                      <TableHead className="w-[20%] text-left px-4 py-2">Delete</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {trashedProject.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={4} className="text-center py-4">
                          No projects found.
                        </TableCell>
                      </TableRow>
                    ) : (
                      trashedProject.map((pro) => (
                        <TableRow key={pro.project_id} className="hover:bg-gray-100">
                          <TableCell className="py-3 px-4 font-medium">{pro.project_name}</TableCell>
                          <TableCell className="py-3 px-4">{pro.project_author}</TableCell>
                          <TableCell className="py-3 px-4">
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <button
                                  onClick={() => setSelectedProjectId(pro.project_id)}
                                  className="text-black hover:text-green-600"
                                >
                                  <ArchiveRestore />
                                </button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                                  <AlertDialogDescription>
                                    This will restore the project and move it back from trash.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                                  <AlertDialogAction
                                    onClick={() => {
                                      if (selectedProjectId) restoreProject(selectedProjectId);
                                    }}
                                  >
                                    Restore
                                  </AlertDialogAction>
                                </AlertDialogFooter>
                              </AlertDialogContent>
                            </AlertDialog>
                          </TableCell>
                          <TableCell className="py-3 px-4">
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <button
                                  onClick={() => setSelectedProjectId(pro.project_id)}
                                  className="text-red-600 hover:text-red-800"
                                >
                                  <Trash2 />
                                </button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                                  <AlertDialogDescription>
                                    This will permanently delete the project. This action cannot be undone.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                                  <AlertDialogAction
                                    className="bg-red-600 hover:bg-red-700"
                                    onClick={() => {
                                      if (selectedProjectId) deleteProject(selectedProjectId);
                                    }}
                                  >
                                    Delete
                                  </AlertDialogAction>
                                </AlertDialogFooter>
                              </AlertDialogContent>
                            </AlertDialog>
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
