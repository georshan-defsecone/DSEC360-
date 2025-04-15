import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import { useEffect, useState } from 'react';
import api from "./api"
import { Link } from "react-router-dom"


function DashboardContent() {
  const [projectData, setProjectData] = useState([]);
  const token = localStorage.getItem("access"); 
  

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
      setProjectData(response.data);
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
    } catch (err) {
      console.error("Failed to move project to trash", err);
    }
  };
  

  useEffect(() => {
    const interval = setInterval(() => {
      fetchData();
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
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
                    <TableHead>Project Author</TableHead>
                    <TableHead>Trash</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {projectData.map((pro, project_id) => (
                    <TableRow key={project_id}>

                      
                      <TableCell></TableCell>
                      <TableCell className="font-medium">
                        <Link to={`/project/${pro.project_id}`}>
                          {pro.project_name}
                        </Link>
                      </TableCell>
                      <TableCell>{pro.project_author}</TableCell>
                      <TableCell>
                        <button onClick={() => moveToTrash(pro.project_id)}>❌</button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </ScrollArea>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}



function Dashboard() {
  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64">
        <Header title="My Projects" />
        <div className="p-4 overflow-auto max-h-[calc(100vh-100px)]">
          <DashboardContent />
        </div>
      </div>
    </div>
  )
}

export default Dashboard
