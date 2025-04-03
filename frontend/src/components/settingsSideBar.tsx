import { useState,useEffect } from "react";
import { Link,useLocation } from "react-router-dom";

const SettingsSideBar = () =>{
    const[activepage,setActivePage]=useState("");
    const location = useLocation();

    useEffect(() => {
       
        const path = location.pathname.split("/").pop();
        setActivePage(path); 
      }, [location]);
   
    
    
    
    const handleLinkClick = (page) => {
        setActivePage(page);
      };
    
    return(<>
<div className="w-120 top-29 h-screen bg-[#d3d3d3]   shadow-lg p-4 fixed  left-0 text-left mt-10 flex flex-col gap-5 justify-start  ">
    <p className="text-4xl font-bold  mt-5 left-10 ml-6 bg-[#d3d3d3] text-black underline underline-offset-4">Settings</p>
    <div className="flex flex-col gap-4 ml-4   text-3xl">
    <p><Link to="/settings/about" onClick={() => handleLinkClick("about")}> <span className={`text-gray-800  hover:bg-gray-200 block p-2 ${activepage === "about" ? "bg-gray-200" : "hover:bg-gray-200"} `} >About</span></Link></p>
    <p><Link to="/settings/advanced" onClick={() => handleLinkClick("advanced")}> <span className={`text-gray-800   hover:bg-gray-200 block p-2 ${activepage === "advanced" ? "bg-gray-200" : "hover:bg-gray-200"} `} >Advanced</span></Link></p>
    <p><Link to="/settings/proxyserver"> <span className={`text-gray-800  hover:bg-gray-200 block p-2 ${activepage === "proxyserver" ? "bg-gray-200" : "hover:bg-gray-200"} `}>Proxy Server</span></Link></p>
    {/* <p><Link to="/settings"> <span className="text-gray-800  hover:bg-gray-200 block p-2">Remote Link</span></Link></p> */}
    <p><Link to="/settings/smtpserver"> <span className={`text-gray-800  hover:bg-gray-200 block p-2 ${activepage === "smtpserver" ? "bg-gray-200" : "hover:bg-gray-200"} `}>SMTP Server</span></Link></p>
    {/* <p><Link to="/settings"> <span className="text-gray-800  hover:bg-gray-200 block p-2">Custom CA</span></Link></p> */}
    <p><Link to="/settings/passwordmgmt"> <span className={`text-gray-800  hover:bg-gray-200 block p-2 ${activepage === "passwordmgmt" ? "bg-gray-200" : "hover:bg-gray-200"} `}>Password Mgmt</span></Link></p>
    {/* <p><Link to="/settings"> <span className="text-gray-800  hover:bg-gray-200 block p-2">Scanner Health</span></Link></p> */}
    <p><Link to="/settings/notifications"> <span className={`text-gray-800  hover:bg-gray-200 block p-2 ${activepage === "notifications" ? "bg-gray-200" : "hover:bg-gray-200"} `}>Notifications</span></Link></p>
    </div>
    
    <p className="text-4xl font-bold bg-[] mt-5 left-10 ml-6 underline underline-offset-4">Accounts</p>
    <div className="flex flex-col gap-5 ml-4 text-3xl">
    <p ><Link to="/settings/myaccount"> <span className={`text-gray-800  hover:bg-gray-200 block p-2 ${activepage === "myaccount" ? "bg-gray-200" : "hover:bg-gray-200"} `}>My Account</span></Link></p>
    <p ><Link to="/settings/user"> <span className={`text-gray-800  hover:bg-gray-200 block p-2 ${activepage === "user" ? "bg-gray-200" : "hover:bg-gray-200"} `}>User</span></Link></p>
    </div>
</div>
</>
)
}
export default SettingsSideBar;