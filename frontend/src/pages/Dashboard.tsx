import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import { useEffect, useState } from 'react';


function DashboardContent() {

  const [scanData, setScanData] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch('http://localhost:8000/api/scans/');
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        const data = await response.json();
        setScanData(data);
      } catch (error) {
        console.error('Error fetching scan data:', error);
      }
    };
    fetchData();
  }, []);


  const handleMoveToTrash = async (scanId: string) => {
    try {
      const response = await fetch(`http://localhost:8000/api/scans/${scanId}/trash/`, {
        method: 'PUT',
      });
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      fetchData(); 
    } catch (error) {
      console.error('Error moving  to trash:', error);
    }
  }

  const fetchData = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/scans/');
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      const data = await response.json();
      setScanData(data);
    } catch (error) {
      console.error('Error fetching scan data:', error);
    }
  };

  useEffect(() => {
    const Interval = setInterval(() => {
      fetchData();
    }, 3000); 
    return () => clearInterval(Interval);
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
                    <TableHead>Scan Author</TableHead>
                    <TableHead>Trash</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {scanData.map((scan, id) => (
                    <TableRow key={id}>
                      <TableCell></TableCell>
                      <TableCell className="font-medium">{scan.project_name}</TableCell>
                      <TableCell>{scan.scan_author}</TableCell>
                      <TableCell><button onClick={()=>{handleMoveToTrash(scan.scan_id)}}>❌</button></TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </ScrollArea>
          </CardContent>
        </Card>
      </div>
    </div>
  )
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
