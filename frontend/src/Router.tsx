import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login"; 
import About from "./pages/About";
import SMTP from "./pages/SMTP";
import ProxyServer from "./pages/ProxyServer";
import AllProjects from "./pages/AllProjects";
import Trash from "./pages/Trash";
import Result from "./pages/Result";


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
    }
    ,
    {
        path: "/settings/SMTP",
        element: <SMTP/>
    }
    ,
    {
        path: "/settings/proxyserver",
        element: <ProxyServer/>
    }
]

export default Router