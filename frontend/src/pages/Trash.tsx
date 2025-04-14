import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { useEffect, useState } from 'react';
import api from "./api"    

export default function Trash() {

  const [trashedProject, setTrashedProject] = useState([]);

  useEffect(() => {
    const fetchTrashedScans = async () => {
      try {
        const response = await api.get('projects/trash/');
        setTrashedProject(response.data);
      } catch (error) {
        console.error('Error fetching trashed project:', error);
      }
    };
  
    fetchTrashedScans();
  }, []);



  return (
    <>
        <div className="flex h-screen text-black">
            <Sidebar settings={false} scanSettings={false} homeSettings={true} />
        <div className="flex-1 flex flex-col ml-64">
            <Header title="Trash" />
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
                    <TableHead>Scan Author</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {trashedProject.map((pro, project_id) => (
                    <TableRow key={project_id}>
                      <TableCell></TableCell>
                      <TableCell className="font-medium">{pro.project_name}</TableCell>
                      <TableCell>{pro.scan_author}</TableCell>
                    </TableRow>
                  ))}
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
  )
}
