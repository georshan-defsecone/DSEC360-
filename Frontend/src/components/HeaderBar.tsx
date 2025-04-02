import logo from "../assets/logo.png";
import { Link } from "react-router-dom";
import { useState } from "react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

const HeaderBar = () => {
    const [dropdownOpen, setDropdownOpen] = useState(false);

    return (
        <div className=" flex items-center justify-between">
            <div className="flex items-center space-x-3">
                <img src={logo} alt="Logo" className="h-10" />
                <h3 className="font-bold">DSEC360+</h3>
            </div>

            <div className="relative">
                <div className="cursor-pointer flex items-center " onClick={() => setDropdownOpen(!dropdownOpen)}>
                    <Avatar>
                        <AvatarImage alt="User Avatar"/>
                        <AvatarFallback>U</AvatarFallback> 
                    </Avatar>
                    <span className="text-m m-2 hover:bg-gray-100">User ▼</span>
                </div>

                {dropdownOpen && (
                    <div className="absolute right-0 mt-2 w-40 rounded-lg p-2 shadow-lg bg-white ">
                        <p className="p-2 hover:bg-gray-100 cursor-pointer rounded-lg ml-20"><Link to="/profile">Profile</Link></p>
                        <p className="p-2 hover:bg-gray-100 cursor-pointer rounded-lg ml-20"><Link to="/settings">Settings</Link></p>
                        <p className="p-2 hover:bg-gray-100 cursor-pointer rounded-lg ml-20">Logout</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default HeaderBar;
