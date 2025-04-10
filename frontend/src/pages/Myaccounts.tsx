import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { MdAccountCircle } from "react-icons/md";
import { FiEdit } from "react-icons/fi";
import { Link } from "react-router-dom";
const Myaccounts = () => {

  return (
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col ml-64 p-8">
          <Header title="My Account" />
          <Card className="min-h-130">
            <CardContent className="p-8">
              <div className="flex items-start gap-8">
                {/* Profile Icon */}
                <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center shadow-md">
                  <MdAccountCircle className="text-gray-600 text-6xl" />
                </div>
  
                {/* User Info and Button */}
                <div className="w-full max-w-md space-y-4">
                  {/* Username Row */}
                  <div className="flex items-center justify-between border-b pb-2">
                    <span className="text-gray-500">Username</span>
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-gray-800">john_doe_91</span>
                      <button className="text-gray-500 hover:text-black transition">
                        <FiEdit className="text-lg" />
                      </button>
                    </div>
                  </div>
  
                  {/* Email Row */}
                  <div className="flex items-center justify-between border-b pb-2">
                    <span className="text-gray-500">Email</span>
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-gray-800">john@example.com</span>
                      <button className="text-gray-500 hover:text-black transition">
                        <FiEdit className="text-lg" />
                      </button>
                    </div>
                  </div>
  
                  {/* Role Row */}
                  <div className="flex justify-between">
                    <span className="text-gray-500">Role</span>
                    <span className="font-medium text-gray-800">Administrator</span>
                  </div>
  
                  {/* Change Password Button */}
                  <div className="pt-6">
                    <Link to="/settings/myaccounts/changepassword">
                    <button className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition">
                      Change Password
                    </button>
                    </Link>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
};

export default Myaccounts;
