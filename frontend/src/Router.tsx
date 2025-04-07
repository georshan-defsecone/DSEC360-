import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";
import About from "./pages/About";
import ScanHome from "./pages/ScanHome";
import ScanCAWindows from "./pages/ScanCAWindows";
import ScanCALinux from "./pages/ScanCALinux";

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
]

export default Router