import Header from "@/components/Header"
import Sidebar from "@/components/Sidebar"
import { useEffect, useState } from 'react';
import api from "./api"
import { useParams } from "react-router-dom";
import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

function ProjectScans() {
    const { project_id } = useParams();
    const [projectData, setProjectData] = useState([]);
    
    useEffect(() => {
        
        const fetchProjectScans = async () => {
            try {
                const response = await api.get(`project/${project_id}/`);
                console.log(response.data.project_name);

                setProjectData(response.data);
               
                
            } catch (error) {
                console.error('Error fetching project scans:', error);
            }
        }
        fetchProjectScans();
    }, [project_id])
    return (
        <div className="flex h-screen text-black">
            <Sidebar settings={false} scanSettings={false} homeSettings={true} />
            <div className="flex-1 flex flex-col ml-64">
                {projectData.project_name && (
                    <Header title={projectData.project_name} />
                )}
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
                                                    <TableHead>Scan Name</TableHead>
                                                    <TableHead>Scan Author</TableHead>
                                                    <TableHead>Scan Status</TableHead>
                                                </TableRow>
                                            </TableHeader>
                                            <TableBody>
                                                {projectData.map((pro, project_id) => (
                                                    <TableRow key={project_id}>
                                                        <TableCell></TableCell>
                                                        <TableCell className="font-medium">{pro.scan_name}</TableCell>
                                                        <TableCell>{pro.scan_author}</TableCell>
                                                        <TableCell>{pro.scan_status}</TableCell>
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
    )
}

export default ProjectScans
