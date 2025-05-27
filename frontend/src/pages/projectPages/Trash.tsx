import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { useEffect, useState } from 'react';
import api from "../api"
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
} from "@/components/ui/alert-dialog"
import { ArchiveRestore, Trash2 } from 'lucide-react';


export default function Trash() {

  const [trashedProject, setTrashedProject] = useState([]);
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  const [isDeleteAllDialogOpen, setIsDeleteAllDialogOpen] = useState(false);

  const fetchTrashedProject = async () => {
    try {
      const response = await api.get('projects/trash/');
      setTrashedProject(response.data);
      console.log(response.data);  // Debug the response data

    } catch (error) {
      console.error('Error fetching trashed project:', error);
    }
  };

  const restoreProject = async (projectId) => {
    try {
      await api.put(`project/trash/${projectId}/`, { trash: false });
      console.log(`Project ${projectId} restored.`);
      fetchTrashedProject();
    } catch (err) {
      console.error("Failed to restore project", err);
    }
  };

  useEffect(() => {
    fetchTrashedProject();
  }, []);

  const deleteProject = async (projectId) => {
    try {
      await api.delete(`project/trash/delete/${projectId}/`);
      console.log(`Project ${projectId} deleted.`);
      fetchTrashedProject(); // refresh the table
    } catch (err) {
      console.error("Failed to delete project", err);
    }
  };

  const deleteAllProjects = async () => {
    try {
      await api.delete('projects/trash/deleteAll'); // Assuming you have an endpoint for deleting all projects
      setTrashedProject([]); // Clear the local state after deletion
      setIsDeleteAllDialogOpen(false); // Close the dialog
      console.log('All projects and related scans have been deleted.');
    } catch (error) {
      console.error('Error deleting all projects:', error);
    }
  };


  return (
    <>
        <div className="flex h-screen text-black pt-20">
            <Sidebar settings={false} scanSettings={false} homeSettings={true} />
        <div className="flex-1 flex flex-col ml-64">
          <Header title="Trash"><AlertDialog>
              <AlertDialogTrigger asChild>
                <button className="flex items-center ml-200">
                  Delete All 
                </button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                  <AlertDialogDescription>
                    This will permanently delete all projects and their related scans. This action cannot be undone.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel onClick={() => setIsDeleteAllDialogOpen(false)}>
                    Cancel
                  </AlertDialogCancel>
                  <AlertDialogAction
                    className="bg-red-600 hover:bg-red-700"
                    onClick={deleteAllProjects}
                  >
                    Delete All
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog></Header>
                <Card className="mt-10 w-[80%] shadow-2xl ml-12">
                  <CardContent className="p-4 px-12">
                    <ScrollArea className="rounded-md border">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Project Name</TableHead>
                            <TableHead>Project Author</TableHead>
                            <TableHead>Restore</TableHead>
                            <TableHead>Delete</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {trashedProject.length === 0 ? (
                            <TableRow>
                              <TableCell colSpan={4} className="text-center">
                              No projects found.
                              </TableCell>
                            </TableRow>
                          ) : (
                            trashedProject.map((pro, project_id) => (
                            <TableRow key={pro.project_id}>
                              <TableCell className="font-medium">{pro.project_name}</TableCell>
                              <TableCell>{pro.project_author}</TableCell>
                              <TableCell>
                                <AlertDialog>
                                  <AlertDialogTrigger asChild>
                                    <button
                                      onClick={() => setSelectedProjectId(pro.project_id)}
                                      className="text-black cursor-pointer "
                                    >
                                      <ArchiveRestore />  {/*  archive button */}
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
                                          if (selectedProjectId) {
                                            restoreProject(selectedProjectId);
                                          }
                                        }}
                                      >
                                        Restore
                                      </AlertDialogAction>
                                    </AlertDialogFooter>
                                  </AlertDialogContent>
                                </AlertDialog>
                              </TableCell>
                              <TableCell>
                                <AlertDialog>
                                  <AlertDialogTrigger asChild>
                                    <button
                                      onClick={() => setSelectedProjectId(pro.project_id)}
                                      className="text-red-600 cursor-pointer"
                                    >
                                      <Trash2/>
                                    </button>
                                  </AlertDialogTrigger>
                                  <AlertDialogContent>
                                    <AlertDialogHeader>
                                      <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                                      <AlertDialogDescription>
                                        This will permanently delete the project from the database. This action cannot be undone.
                                      </AlertDialogDescription>
                                    </AlertDialogHeader>
                                    <AlertDialogFooter>
                                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                                      <AlertDialogAction
                                        className="bg-red-600 hover:bg-red-700"
                                        onClick={() => {
                                          if (selectedProjectId) {
                                            deleteProject(selectedProjectId);
                                          }
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
                    </ScrollArea>
                  </CardContent>
                </Card>
              </div>
            </div>

    </>
  )
}

