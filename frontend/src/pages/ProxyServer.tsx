import { Card, CardContent } from "@/components/ui/card"
import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import { Button } from "@/components/ui/button"
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
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
  } from "@/components/ui/select"
  


const ProxyServer = () => {
    return (<>
    <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col ml-64 p-8 ">
          <Header title="Proxy Server" />
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
                  <Select>
  <SelectTrigger className="w-[180px]">
    <SelectValue placeholder="Select" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="light">AutoDetect</SelectItem>
    <SelectItem value="None">None</SelectItem>
    <SelectItem value="Basic">Basic</SelectItem>
    <SelectItem value="Digest">Digest</SelectItem>
    <SelectItem value="NTLM">NTLM</SelectItem>
  </SelectContent>
</Select>

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