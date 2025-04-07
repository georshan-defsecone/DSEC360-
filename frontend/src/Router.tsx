import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login"; 
import About from "./pages/About";
import ScanHome from "./pages/ScanHome";

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
    },
    {
        path: "/scans",
        element: <ScanHome/>
    },
]

export default Router