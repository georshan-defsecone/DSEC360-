import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";

const Router = [
    {  
        path: "/",
        element: <Dashboard/>
    },
    {
        path: "/login",
        element: <Login/>
    }
]

export default Router