// src/components/ProtectedRoute.tsx
import { JSX, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { verifyToken } from "@/utils/auth"; // Your function

const ProtectedRoute = ({ children }: { children: JSX.Element }) => {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const checkAuth = async () => {
      const valid = await verifyToken();
      setIsAuthenticated(valid);
      setIsLoading(false);
      if (!valid) {
        navigate("/login"); // 👈 Redirect to login if not valid
      }
    };
    checkAuth();
  }, [navigate]);

  //if (isLoading) return <div>Loading...</div>;

  return isAuthenticated ? children : null;
};

export default ProtectedRoute;
