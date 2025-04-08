import { Card, CardContent } from "@/components/ui/card"
import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import { Button } from "@/components/ui/button"
import {
    ColumnDef,
    ColumnFiltersState,
    SortingState,
    VisibilityState,
    flexRender,
    getCoreRowModel,
    getFilteredRowModel,
    getPaginationRowModel,
    getSortedRowModel,
    useReactTable,
  } from "@tanstack/react-table"
  import { ArrowUpDown, ChevronDown, MoreHorizontal } from "lucide-react"
  import { Checkbox } from "@/components/ui/checkbox"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuPortal,
  DropdownMenuSeparator,
  DropdownMenuShortcut,
  DropdownMenuSub,
  DropdownMenuSubContent,
  DropdownMenuSubTrigger,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { useState } from "react"
import { Input } from "@/components/ui/input"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"


const ProxyServer = () => {
    const [buttonText, setButtonText] = useState('Open'); // State to hold the button text

    const handleItemClick = (text) => {
      setButtonText(text); // Update the button text when a dropdown item is clicked
    };
    return (<>
    <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8">
          <Header />
          <Card className="min-h-130">
            <CardContent className="p-2 pl-12">
              <div className="flex flex-col items-start  space-y-10"> {/* Add space between rows */}
                {/* Row 1 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Host:</p> {/* Adjust width of label */}
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 2 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Port:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 3 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">UserName:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 4 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">Password:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>

                {/* Row 5 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">AuthMethod:</p>
                  <DropdownMenu>
      <DropdownMenuTrigger asChild>
      <Button variant="outline">{buttonText}</Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-56">
      <DropdownMenuGroup>
      <DropdownMenuItem onClick={() => handleItemClick('AutoDetect')}>AutoDetect</DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleItemClick('None')}>None</DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleItemClick('Basic')}>Basic</DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleItemClick('Digest')}>Digest</DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleItemClick('NTLM')}>NTLM</DropdownMenuItem>
       </DropdownMenuGroup>
      </DropdownMenuContent>   
      </DropdownMenu>
                </div>

                {/* Row 6 */}
                <div className="flex items-center">
                  <p className="text-lg font-semibold w-40">User Agent:</p>
                  <Input type="text" className="w-60" placeholder="" />
                </div>
              </div>
            </CardContent>
          </Card>
          <Button variant="outline" className="w-20 mt-6 ml-auto mr-6">Save</Button>

        </div>
      </div>
    </>)
}


export default ProxyServer