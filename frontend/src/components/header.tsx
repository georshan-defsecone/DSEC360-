import React, { useState } from "react";
import logo from "../assets/logo.png";
import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
  } from "@/components/ui/dropdown-menu"
  

const HeaderBar = () => {
    const [dropdownOpen, setDropdownOpen] = useState(false);

    return (
        <div className="fixed top-0 left-0 w-full p-[15px] bg-[#333] flex justify-between items-center text-white">
            <div className="flex items-center gap-2">
            <img src={logo} className="w-14" alt="Logo" />
            </div>
            <div>
            <h3 className="headertitle font-[Roboto] text-5xl">DSEC360+ </h3>
            </div>
            <div className="mr-4">
            <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" className="relative cursor-pointer p-[15px] bg-[#444] rounded-[5px] text-xl w-30 h-12"><h2 className="text-5xl">User</h2></Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-40">
      <DropdownMenuItem className="text-xl">
      Profile
      </DropdownMenuItem>
      <DropdownMenuSeparator />
      <DropdownMenuItem className="text-xl">
      Settings
      </DropdownMenuItem>
      <DropdownMenuSeparator />
      <DropdownMenuItem className="text-xl">
      Logout
      </DropdownMenuItem>
      </DropdownMenuContent>
        </DropdownMenu>
        </div>
        </div>
    );
};

export default HeaderBar;