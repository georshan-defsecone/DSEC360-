import { Card, CardContent } from "@/components/ui/card"
import { Checkbox } from "@/components/ui/checkbox"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"

const scanData = [
  { name: "Ram", owner: "test", Date: "", modified: "April 3 at 11:01 AM", status: "✔️" },
  { name: "Test 2", owner: "test2", Date: "", modified: "", status: "⏳"  },
  { name: "Test", owner: "def", Date: "", modified: "", status: "✔️"  },
  { name: "rambo", owner: "rambo", Date: "", modified: "", status: "✔️",  },
  { name: "defsecone", owner: "defsecone", Date: "", modified: "", status: "✔️" },
  { name: "vicky", owner: "vicky", Date: "", modified: "  ", status: "✔️",  },
  { name: "test123", owner: "test", Date: "", modified: "March 18 at 3:35 PM", status: "✔️" },
]


function DashboardContent() {
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
                    <TableHead>Name</TableHead>
                    <TableHead>Owner</TableHead>
                    {/* <TableHead>Schedule</TableHead> */}
                    <TableHead>Last Modified</TableHead>
                    <TableHead>Trash</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {scanData.map((scan, idx) => (
                    <TableRow key={idx}>
                      <TableCell></TableCell>
                      <TableCell className="font-medium">{scan.name}</TableCell>
                      <TableCell>{scan.owner}</TableCell>
                      {/* <TableCell>{scan.schedule}</TableCell> */}
                      <TableCell className="font-medium">{scan.modified}</TableCell>
                      <TableCell>❌</TableCell>
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
