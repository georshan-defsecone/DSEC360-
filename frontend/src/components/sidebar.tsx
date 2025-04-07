import React, { useState } from "react";
import { Link } from "react-router-dom";
import VulnerabilityManagement from "./vulnerabilitymanagement";
import ConfigurationAudit from "./configurationaudit";
import CompromiseAssesment from "./compromiseassesment";

const SideBar =()=>{
    return(
        <div className="fixed top-30 left-0 w-128 h-screen text-2xl bg-[#444] p-4 pt-8">
            <div className="flex flex-col items-start text-2xl h-screen p-4 gap-20">
            <VulnerabilityManagement/>
            <ConfigurationAudit/>
            <CompromiseAssesment/>
            </div>
            
        </div>
    )
}


export default SideBar;