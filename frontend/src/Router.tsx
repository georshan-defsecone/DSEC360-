import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login"; 
import About from "./pages/About";
import SMTP from "./pages/SMTP";
import ProxyServer from "./pages/ProxyServer";

const Router = [
    {  
        path: "/",
        element: <Dashboard/>
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