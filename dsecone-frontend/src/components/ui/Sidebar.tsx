import VulnerabilityManagement from "./VulnerabilityManagement"
import ConfigurationAudit from "./ConfigurationAudit"
import CompromiseAssessment from "./CompromiseAssessment"

const Sidebar = () => {
    return (
        <>
            <div className="w-65 text-black p-4 fixed top-16 bg-[#d3d3d3] left-0 h-[calc(100vh-0rem)] z-40">
                <div className="flex flex-col gap-2">
                    <VulnerabilityManagement></VulnerabilityManagement>
                    <ConfigurationAudit></ConfigurationAudit>
                    <CompromiseAssessment></CompromiseAssessment>
                </div>
            </div>
        </>
    )
}

export default Sidebar