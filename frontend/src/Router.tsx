import ProtectedRoute from "./components/ProtectedRoute";

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
import Myaccounts from "./pages/Myaccounts";
import CreateUser from "./pages/CreateUser";

const Router = [
  {
    path: "/",
    element: (
      <ProtectedRoute>
        <Dashboard />
      </ProtectedRoute>
    ),
  },
  {
    path: "/dashboard/allprojects",
    element: (
      <ProtectedRoute>
        <AllProjects />
      </ProtectedRoute>
    ),
  },
  {
    path: "/dashboard/results",
    element: (
      <ProtectedRoute>
        <Result />
      </ProtectedRoute>
    ),
  },
  {
    path: "/dashboard/trash",
    element: (
      <ProtectedRoute>
        <Trash />
      </ProtectedRoute>
    ),
  },
  {
    path: "/scan",
    element: (
      <ProtectedRoute>
        <ScanHome />
      </ProtectedRoute>
    ),
  },
  {
    path: "/scan/windows",
    element: (
      <ProtectedRoute>
        <ScanCAWindows />
      </ProtectedRoute>
    ),
  },
  {
    path: "/scan/linux",
    element: (
      <ProtectedRoute>
        <ScanCALinux />
      </ProtectedRoute>
    ),
  },
  {
    path: "/settings/SMTP",
    element: (
      <ProtectedRoute>
        <SMTP />
      </ProtectedRoute>
    ),
  },
  {
    path: "/settings/proxyserver",
    element: (
      <ProtectedRoute>
        <ProxyServer />
      </ProtectedRoute>
    ),
  },
  {
    path: "/settings/users",
    element: (
      <ProtectedRoute>
        <Users />
      </ProtectedRoute>
    ),
  },
  {
    path: "/settings/myaccounts",
    element: (
      <ProtectedRoute>
        <Myaccounts />
      </ProtectedRoute>
    ),
  },
  {
    path: "/settings/users/createuser",
    element: (
      <ProtectedRoute>
        <CreateUser />
      </ProtectedRoute>
    ),
  },
  {
    path: "/settings/about",
    element: (
      <ProtectedRoute>
        <About />
      </ProtectedRoute>
    ),
  },

  // 🟢 Public routes
  {
    path: "/login",
    element: <Login />,
  },
];

export default Router;
