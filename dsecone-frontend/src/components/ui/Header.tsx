import logo from "../../assets/logo.png"

import { Button } from "./button"

import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger
} from "@radix-ui/react-dropdown-menu"

const Header = () => {
    return(
        <>
            <div className="flex justify-between p-2 items-center bg-[#333]">
                <div className="flex justify-between items-center gap-3 text-white">
                    <img src={logo} alt="defsecone" className="h-12"/>
                    <h2 className="font-bold text-2xl">DSEC360+ </h2>
                </div>
                <div className="mr-4 text-black">
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild> 
                        <Button variant="outline" className="text-white bg-[#444]">👤<h1>User</h1>▼</Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent className="w-56 bg-[#333] text-white border border-t-0 border-gray-700 shadow-lg">
                            <DropdownMenuItem className="hover:bg-gray-700 px-4 py-2 transition-all focus:outline-none focus:ring-2 focus:ring-gray-500">Profile</DropdownMenuItem>
                            <DropdownMenuItem className="hover:bg-gray-700 px-4 py-2 transition-all focus:outline-none focus:ring-2 focus:ring-gray-500">Settings</DropdownMenuItem>
                            <DropdownMenuItem className="hover:bg-gray-700 px-4 py-2 transition-all focus:outline-none focus:ring-2 focus:ring-gray-500">Profile</DropdownMenuItem>

                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </div>
        </>
    )
}

export default Header