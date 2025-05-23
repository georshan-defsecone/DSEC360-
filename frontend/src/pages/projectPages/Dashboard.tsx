import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import { useEffect, useState } from 'react';
import api from "../api"
import { Link } from "react-router-dom"
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




function DashboardContent() {
  const [projects, setProjects] = useState([]);
  const token = localStorage.getItem("access"); 
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  

  const fetchData = async () => {
    if (!token) {
      console.error('JWT Token not found');
      return;  // Token is not found, no API call will be made.
    }
    try {
      const response = await api.get('projects/', {
        headers: {
          'Authorization': `Bearer ${token}`,  // Include JWT token
        },
      });
      console.log("JWT Token: ", token);  // Debug the token
      setProjects(response.data);
      console.log(response.data);  // Debug the response data
    } catch (error) {
      console.error('Error fetching project data:', error);
    }
  };
  useEffect(() => {
    fetchData();
  }, [token]);

  const moveToTrash = async (projectId: string) => {
    try {
      await api.put(`project/trash/${projectId}/`, { trash: true });
      console.log(`Project ${projectId} moved to trash.`);
      fetchData();  // Refresh the list after moving the project to trash
    } catch (err) {
      console.error("Failed to move project to trash", err);
    }
  };
  


  return (
        <Card className="mt-10 w-[80%] shadow-2xl ml-12">
          <CardContent className="p-4 px-12">
            <ScrollArea className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow className="text-center p-4">
                    <TableHead>Project Name</TableHead>
                    <TableHead>Project Author</TableHead>
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
                          <TableCell className="font-medium">
                            <Link to={`/project/${pro.project_id}`}>
                              {pro.project_name}
                            </Link>
                          </TableCell>
                          <TableCell>{pro.project_author}</TableCell>
                          <TableCell>
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <button
                                  onClick={() =>
                                    setSelectedProjectId(pro.project_id)
                                  }
                                >
                                  ❌
                                </button>
                              </AlertDialogTrigger>

                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>
                                    Are you sure?
                                  </AlertDialogTitle>
                                  <AlertDialogDescription>
                                    This will move the project to trash. You can
                                    restore it later if needed.
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
  );
}



function Dashboard() {
  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64 pt-20">
        <Header title="My Projects"></Header>
          <DashboardContent />

      </div>
    </div>
  )
}

export default Dashboard
