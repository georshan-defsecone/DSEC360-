import logo from "../../assets/logo.png"
import { CircleUser } from "lucide-react"
import { Button } from "./button"

import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger
} from "@radix-ui/react-dropdown-menu"

const Header = () => {
    return(
        <>
            <div className="flex justify-between p-2 items-center bg-[#333] fixed top-0 right-0 left-0">
                <div className="flex justify-between items-center gap-3 text-white">
                    <img src={logo} alt="defsecone" className="h-12"/>
                    <h2 className="font-bold text-2xl">DSEC360+ </h2>
                </div>
                <div className="mr-4 text-black">
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                        <div className="flex gap-4 items-center text-white"><h1>User</h1><CircleUser size={32}/></div>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent className="w-64 bg-white text-black border border-t-0  shadow-lg mt-2 mr-2">
                            <DropdownMenuItem className="px-4 py-2">
                                <div className="flex justify-start items-center gap-10">
                                    <CircleUser  className="ml-4" size={48}></CircleUser>
                                    <div className="flex flex-col gap-0 items-start">
                                        <h1>User</h1>
                                        <h1>Gmail.com</h1>
                                    </div>
                                </div>
                            </DropdownMenuItem>
                            <DropdownMenuItem className="px-4 py-2">
                                <div className="flex justify-evenly gap-2 pb-2">
                                    <Button variant="outline" className="text-black w-22">Accounts</Button>
                                    <Button variant="outline" className="text-black w-22">Logout</Button>
                                </div>
                            </DropdownMenuItem>

                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </div>
        </>
    )
}

export default Header