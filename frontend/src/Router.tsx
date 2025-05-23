import Dashboard from "./pages/projectPages/Dashboard";
import Login from "./pages/Login";
import About from "./pages/About";


import SMTP from "./pages/settingsPages/SMTP";
import ProxyServer from "./pages/settingsPages/ProxyServer";
import AllProjects from "./pages/projectPages/AllProjects";
import Trash from "./pages/projectPages/Trash";
import Result from "./pages/projectPages/Result";
import Advanced from "./pages/settingsPages/Advanced";
import LDAP from "./pages/settingsPages/LDAP";

import ScanCAWindows from "./pages/scanPages/ScanCAWindows";
import ScanCALinux from "./pages/scanPages/ScanCALinux";
import ScanCAFirewall from "./pages/scanPages/ScanCAFirewall";
import ScanCACloud from "./pages/scanPages/ScanCACloud";
import ScanCAContainerOrchestration from "./pages/scanPages/ScanCAContainerOrchestration";
import ScanCADatabases from "./pages/scanPages/ScanCADatabases";
import ScanCANetworkDevices from "./pages/scanPages/ScanCANetworkDevices";
import ScanIOCLinux from "./pages/scanPages/ScanIOCLinux";
import ScanIOCWindows from "./pages/scanPages/ScanIOCWindows";
import ScanCAWAServers from "./pages/scanPages/ScanCAWAServers";
import ScanHome from "./pages/scanPages/ScanHome";
import ScanADWindows from "./pages/scanPages/ScanADWindows";

import Users from "./pages/settingsPages/Users";
import Myaccounts from "./pages/settingsPages/Myaccounts";
import CreateUser from "./pages/settingsPages/CreateUser";

import ProjectScans from "./pages/projectPages/ProjectScans";

import Error404 from "./pages/404Error";

import ProtectedRoute from "./components/ProtectedRoute";
import RequireAdmin from "./components/RequireAdmin";

const Router = [
    {
        path: "/",
        element: <ProtectedRoute><RequireAdmin><Dashboard/></RequireAdmin></ProtectedRoute>
    },
    {
        path: "/dashboard/allprojects",
        element: <AllProjects/>
    },
    {
        path: "/dashboard/results",
        element: <Result/>
    },
    {
        path: "/dashboard/trash",
        element: <Trash/>
    },
    {
        path: "/project/:project_id",
        element: <ProjectScans/>
    },
    {
        path: "/login",
        element: <Login/>
    },
    {
        path: "/settings/about",
        element: <About/>
    },
    {
        path: "/scan",
        element: <ScanHome/>
    },
    {
        path: "/scan/configaudit/windows",
        element: <ScanCAWindows/>
    },
    {
        path: "/scan/configaudit/linux",
        element: <ScanCALinux/>
    },
    {
        path: "/scan/configaudit/firewall",
        element: <ScanCAFirewall/>
    },
    {
        path: "/scan/configaudit/cloud",
        element: <ScanCACloud/>
    },
    {
        path: "/scan/configaudit/containersAndOrchestration",
        element: <ScanCAContainerOrchestration/>
    },
    {
        path: "/scan/configaudit/databases",
        element: <ScanCADatabases/>
    },
    {
        path: "/scan/configaudit/networkdevices",
        element: <ScanCANetworkDevices/>
    },
    {
        path: "/scan/ioc/linux",
        element: <ScanIOCLinux/>
    },
    {
        path: "/scan/ioc/windows",
        element: <ScanIOCWindows/>
    },
    {
        path: "/scan/configaudit/WAservers",
        element: <ScanCAWAServers/>
    },
    {
        path: "/scan/ad/windows",
        element: <ScanADWindows/>
    },
    {
        path: "/settings/SMTP",
        element: <SMTP/>
    },
    {
        path: "/settings/proxyserver",
        element: <ProxyServer/>
    }
    ,
    {
        path: "/settings/users",
        element: <Users/>
    }
    ,
    {
        path: "/settings/myaccounts",
        element: <Myaccounts/>
    },
    {
        path: "/settings/users/createuser",
        element: <CreateUser/>
    },
    {
        path:"/settings/advance",
        element: <Advanced/>
    },
    {
        path:"/settings/ldap",
        element: <LDAP/>
    },
    {
        path: "*",
        element: <Error404/>
    }
]

export default Router;
