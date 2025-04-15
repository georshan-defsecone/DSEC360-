import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";
import About from "./pages/About";
import SMTP from "./pages/SMTP";
import ProxyServer from "./pages/ProxyServer";
import AllProjects from "./pages/AllProjects";
import Trash from "./pages/Trash";
import Result from "./pages/Result";

import ScanHome from "./pages/scanPages/ScanHome";
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

import Users from "./pages/Users";
import Myaccounts from "./pages/Myaccounts";
import CreateUser from "./pages/CreateUser";
import path from "path";
import Advanced from "./pages/Advanced";
import LDAP from "./pages/LDAP";
const Router = [
    {
        path: "/",
        element: <Dashboard/>
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
    }
]

export default Router;
