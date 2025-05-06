import { useEffect, useState } from "react";
import api from "./api";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";
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
import { Link } from "react-router-dom";

const AllProjectsPage = () => {
  const [projects, setProjects] = useState([]);
  const [selectedProjectId, setSelectedProjectId] = useState(null);

  const fetchProjects = async () => {
    try {
      const response = await api.get("all-projects/", {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("access")}`,
        },
      });
      setProjects(response.data);
    } catch (error) {
      console.error("Error fetching all projects:", error);
    }
  };

  useEffect(() => {
    fetchProjects();
  }, []);

  const moveToTrash = async (projectId: string) => {
    try {
      await api.put(
        `project/trash/${projectId}/`, { trash: true },
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("access")}`,
          },
        }

      );
      console.log(`Project ${projectId} moved to trash.`);
      // Refresh project list
      fetchProjects();
    } catch (error) {
      console.error("Error moving project to trash:", error);
    }
  };

  return (
    <>
        <div className="flex h-screen text-black pt-18">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64">
        <Header title="All Projects" ><Link to={'/scan'} className="flex items-center ml-200" >New scans</Link></Header>
        <div className="p-4 overflow-auto max-h-[calc(100vh-100px)]">
          <div className="grid lg:grid-cols-1 gap-4">
            <div className="col-span-2">
              <Card className="mt-3 w-full">
                <CardContent className="p-4">
                  <ScrollArea className="rounded-md border">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead className="w-[40px]"></TableHead>
                          <TableHead>Project Name</TableHead>
                          <TableHead>Author</TableHead>
                          <TableHead>Trash</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {projects.length === 0 ? (
                          <TableRow>
                            <TableCell colSpan={4} className="text-center">
                              No projects found.
                            </TableCell>
                          </TableRow>
                        ) : (
                          projects.map((pro) => (
                            <TableRow key={pro.project_id}>
                              <TableCell></TableCell>
                              <TableCell className="font-medium">
                                <Link to={`/project/${pro.project_id}`}>
                                  {pro.project_name}
                                </Link>
                              </TableCell>
                              <TableCell>{pro.project_author}</TableCell>
                              <TableCell>
                                <AlertDialog>
                                  <AlertDialogTrigger asChild>
                                    <button onClick={() => setSelectedProjectId(pro.project_id)}>❌</button>
                                  </AlertDialogTrigger>

                                  <AlertDialogContent>
                                    <AlertDialogHeader>
                                      <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                                      <AlertDialogDescription>
                                        This will move the project to trash. You can restore it later if needed.
                                      </AlertDialogDescription>
                                    </AlertDialogHeader>
                                    <AlertDialogFooter>
                                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                                      <AlertDialogAction
                                        onClick={() => {
                                          if (selectedProjectId) {
                                            moveToTrash(selectedProjectId);
                                          }
                                        }}
                                      >
                                        Move to Trash
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
                  </ScrollArea>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </div>
    </div>
    </>
  );
};

export default AllProjectsPage;
