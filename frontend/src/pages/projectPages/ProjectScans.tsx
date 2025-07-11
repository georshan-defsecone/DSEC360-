import Header from "@/components/Header";
import Sidebar from "@/components/Sidebar";
import { useEffect, useState } from "react";
import api from "../api";
import { Link, useParams, useNavigate } from "react-router-dom"; // ⬅️ add useNavigate
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

function ProjectScans() {
  const { project_id } = useParams();
  const navigate = useNavigate(); // ⬅️ set up navigate

  const [scans, setScans] = useState([]);
  const [projectName, setProjectName] = useState("");

  useEffect(() => {
    const fetchScans = async () => {
      try {
        const response = await api.get(`scans/project/${project_id}/`);
        setScans(response.data);
      } catch (err) {
        console.error("Failed to fetch scans", err);
      }
    };

    const fetchProjectName = async () => {
      try {
        const response = await api.get(`project/${project_id}/`);
        setProjectName(response.data.project_name);
      } catch (err) {
        console.error("Failed to fetch project name", err);
      }
    };

    fetchProjectName();
    fetchScans();
  }, [project_id]);

  // ————————————————————————————————————————————————————————————————
  // helper to build the route safely (handles spaces & symbols)
  const goToScan = (scanName: string) => {
    navigate(
      `/scan/scanresult/${encodeURIComponent(projectName)}/${encodeURIComponent(
        scanName
      )}`
    );
  };
  // ————————————————————————————————————————————————————————————————

  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64">
        <Header title={projectName}>
          <Link to="/scan" className="flex items-center ml-200">
            New scans
          </Link>
        </Header>

        <div className="p-4 overflow-auto max-h-[calc(100vh-100px)]">
          <div className="grid lg:grid-cols-1 gap-4">
            <div className="col-span-2">
              <Card className="mt-3 w-full">
                <CardContent className="p-4">
                  <ScrollArea className="rounded-md border">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead className="w-[40px]" />
                          <TableHead>Scan Name</TableHead>
                          <TableHead>Scan Author</TableHead>
                          <TableHead>Scan Status</TableHead>
                        </TableRow>
                      </TableHeader>

                      <TableBody>
                        {scans.map((scan, i) => (
                          <TableRow
                            key={i}
                            onClick={() => goToScan(scan.scan_name)}
                            className="cursor-pointer hover:bg-gray-100 transition-colors"
                          >
                            <TableCell />
                            <TableCell className="font-medium text-black">
                              {scan.scan_name}
                            </TableCell>
                            <TableCell className="text-black">
                              {scan.scan_author}
                            </TableCell>
                            <TableCell className="text-black">
                              {scan.scan_status}
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
        </div>
      </div>
    </div>
  );
}

export default ProjectScans;
