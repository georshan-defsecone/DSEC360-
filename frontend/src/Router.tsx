import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login"; 
import About from "./pages/About";

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
]

export default Router