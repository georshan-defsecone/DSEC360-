import VulnerabilityManagement from "./VulnerabilityManagement"
import ConfigurationAudit from "./ConfigurationAudit"
import CompromiseAssessment from "./CompromiseAssessment";


const Sidebar = ({ setActivePage }) => {
    return (
        <div className="sidebar">
            <VulnerabilityManagement setActivePage={setActivePage} />
            <ConfigurationAudit setActivePage={setActivePage} />
            <CompromiseAssessment setActivePage={setActivePage}/>
        </div>
    );
};

export default Sidebar;
