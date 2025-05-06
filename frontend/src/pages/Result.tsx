import Header from "@/components/Header"
import Sidebar from "@/components/Sidebar"
import { useEffect, useState } from 'react';
import api from "./api"
import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

function ProjectScans() {

    const [scans, setScans] = useState([]);
    
    useEffect(() => {
      const fetchScans = async () => {
        try {
          const response = await api.get('scans/user', {
            headers: {
              Authorization: `Bearer ${localStorage.getItem("access")}`,
            },
          });
          setScans(response.data);
        } catch (err) {
          console.error("Error fetching scans:", err);
        }
      };
      fetchScans();
    }, []);
    
    
    return (
        <div className="flex h-screen text-black">
            <Sidebar settings={false} scanSettings={false} homeSettings={true} />
            <div className="flex-1 flex flex-col ml-64">
                    <Header title={"Results"}></Header>
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
                                                {scans.map((scan, i) => (
                                                    <TableRow key={i}>
                                                        <TableCell></TableCell>
                                                        <TableCell className="font-medium">{scan.scan_name}</TableCell>
                                                        <TableCell>{scan.scan_author}</TableCell>
                                                        <TableCell>{scan.scan_status}</TableCell>
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
