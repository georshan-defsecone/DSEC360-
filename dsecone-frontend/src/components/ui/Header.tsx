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
                    <h3>DSEC360+ </h3>
                </div>
                <div className="mr-4 text-white">
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="outline">User</Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent className="w-56">

                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </div>
        </>
    )
}

export default Header