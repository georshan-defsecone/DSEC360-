import Header from "@/components/Header"
import Sidebar from "@/components/Sidebar"
import { useParams } from "react-router-dom";
import { Card, CardContent } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

function ProjectScans() {
    const { projectName } = useParams();
    return (
        <div className="flex h-screen text-black">
            <Sidebar settings={false} scanSettings={false} homeSettings={true} />
            <div className="flex-1 flex flex-col ml-64">
                <Header title={projectName} />
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
                                                    <TableHead></TableHead>
                                                    <TableHead></TableHead>
                                                    <TableHead></TableHead>
                                                </TableRow>
                                            </TableHeader>
                                            <TableBody>
                                                
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
