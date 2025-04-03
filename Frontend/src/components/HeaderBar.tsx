import logo from "../assets/logo.png";
import { Link } from "react-router-dom";
import { useState } from "react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { CircleUser } from 'lucide-react';
import { Button, buttonVariants } from "@/components/ui/button"

const HeaderBar = () => {
    const [dropdownOpen, setDropdownOpen] = useState(false);

    return (
        <div className=" flex items-center justify-between bg-[#333] w-full px-6 py-3 z-50 fixed top-0 left-0 shadow-lg">
            <div className="flex items-center space-x-3">
                <img src={logo} alt="Logo" className="h-10" />
                <h3 className="font-bold text-white">DSEC360+</h3>
            </div>

            <div className=" fixed right-0 top-0 m-5">
                <div className="cursor-pointer flex items-center " onClick={() => setDropdownOpen(!dropdownOpen)}>
                    <span className="text-m m-2 text-white">Username!!</span>
                    <Avatar>
                        <AvatarImage alt="User Avatar"/>
                        <AvatarFallback>U</AvatarFallback> 
                    </Avatar>
                </div>

                {dropdownOpen && (
                    <div className="absolute right-0 mt-8 w-60 h-50 rounded-lg p-2 shadow-lg bg-white ">
                        <div className="flex items-center space-x-5 mt-10 mx-2">
                            <CircleUser className="w-12 h-12" />
                            <div>
                                <p className="font-semibold">User</p>
                                <p className="text-gray-600">@gmail.com</p>
                            </div>
                        </div>
                        <div className="flex space-x-3 mx-6 mt-6">
                            <Link to="/account" className={buttonVariants({ variant: "outline"})}>Accounts</Link>
                            <Link to="/logout" className={buttonVariants({ variant: "outline" })}>Logout</Link>
                        </div>

                            {/* 
                        <Link to="/account" className="p-2 hover:bg-gray-100 cursor-pointer rounded-lg ">account</Link>
                            <Link to="/settings" className="p-2 hover:bg-gray-100 cursor-pointer rounded-lg ">Settings</Link>
                            <Link to="/logout" className="p-2 hover:bg-gray-100 cursor-pointer rounded-lg ">Logout</Link>    */}
                    </div>
                )}
            </div>
        </div>
    );
};

export default HeaderBar;
