// src/routes/RequireAdmin.tsx
import { Navigate } from "react-router-dom";
import { jwtDecode } from "jwt-decode";
import axios from "axios";
import { JSX, useEffect, useState } from "react";

interface Props {
  children: JSX.Element;
}

const RequireAdmin = ({ children }: Props) => {
  const [isValidating, setIsValidating] = useState(true);
  const [isAuthorized, setIsAuthorized] = useState(false);

  useEffect(() => {
    const validateToken = async () => {
      let access = localStorage.getItem("access");
      const refresh = localStorage.getItem("refresh");

      try {
        if (!access || !refresh) {
          setIsAuthorized(false);
          setIsValidating(false);
          return;
        }

        const decoded: any = jwtDecode(access);
        const currentTime = Date.now() / 1000;

        // If token is expired
        if (decoded.exp < currentTime) {
          console.log("Access token expired. Attempting refresh...");

          const response = await axios.post(
            "http://localhost:8000/api/token/refresh/", // 🔁 Update to your actual refresh endpoint
            { refresh }
          );

          access = response.data.access;
          localStorage.setItem("access", access);
        }

        // Decode the latest token
        const finalDecoded: any = jwtDecode(access);
        const isAdmin = finalDecoded?.is_admin;

        if (isAdmin) {
          setIsAuthorized(true);
        } else {
          setIsAuthorized(false);
        }
      } catch (error) {
        console.error("Token validation/refresh failed:", error);
        setIsAuthorized(false);
      } finally {
        setIsValidating(false);
      }
    };

    validateToken();
  }, []);

  if (isValidating) {
    return <div className="text-center mt-20">Checking admin access...</div>; // or a loader
  }

  if (!isAuthorized) {
    return <Navigate to="/unauthorized" />;
  }

  return children;
};

export default RequireAdmin;
