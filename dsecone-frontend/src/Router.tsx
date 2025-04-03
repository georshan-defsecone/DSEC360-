import Home from "./App"
import AssetDiscovery from "./pages/AssetDiscovery"
import Ports from "./pages/Ports"

const Router = [
    {
        path: "/",
        element: <Home/>
    },
    {
        path: "/asset-discovery",
        element: <AssetDiscovery/>
    },
    {
        path: "/ports-service-enumeration",
        element: <Ports/>
    },
]

export default Router