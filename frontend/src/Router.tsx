import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";
import About from "./pages/About";
import SMTP from "./pages/SMTP";
import ProxyServer from "./pages/ProxyServer";
import AllProjects from "./pages/AllProjects";
import Trash from "./pages/Trash";
import Result from "./pages/Result";

import ScanHome from "./pages/ScanHome";
import ScanCAWindows from "./pages/ScanCAWindows";
import ScanCALinux from "./pages/ScanCALinux";
import Users from "./pages/Users";

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
        path: "/scan/windows",
        element: <ScanCAWindows/>
    },
    {
        path: "/scan/linux",
        element: <ScanCALinux/>
    },
    {
        path: "/settings/SMTP",
        element: <SMTP/>
    }
    ,
    {
        path: "/settings/proxyserver",
        element: <ProxyServer/>
    }
    ,
    {
        path: "/settings/users",
        element: <Users/>
    }
]

export default Router