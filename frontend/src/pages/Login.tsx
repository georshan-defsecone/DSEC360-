import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import api from "./api";

const Login: React.FC = () => {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState<"success" | "error" | "">("");

  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(""); // Reset message on submit

    try {
      const response = await api.post("token/", {
        username,
        password,
      });

      const { access, refresh } = response.data;

      localStorage.setItem("access", access);
      localStorage.setItem("refresh", refresh);
      setMessage("Login successful! Redirecting...");
      setMessageType("success");

      // Delay before navigation to show success message
      setTimeout(() => {
        navigate("/");
      }, 1500);
    } catch (error) {
      if (error.response?.status === 401) {
        setMessage("Invalid username or password.");
      } else {
        setMessage("An error occurred. Please try again.");
        console.error("Login Error:", error);
      }
      setMessageType("error");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 px-4">
      <div className="flex flex-col md:flex-row w-full max-w-2xl h-auto md:h-[400px] rounded-xl overflow-hidden shadow-2xl bg-white">
        {/* Left Panel */}
        <div className="md:w-[30%] w-full bg-neutral-800 flex flex-col items-center justify-center p-6">
          <img
            src="/logo.png"
            alt="Company Logo"
            className="w-24 h-24 mb-3 shadow-lg rounded-full"
          />
          <h1 className="text-lg font-semibold text-white">DSEC360+</h1>
        </div>

        {/* Right Panel */}
        <div className="md:w-[70%] w-full flex items-center justify-center p-5 bg-white">
          <div className="w-full max-w-60">
            <h2 className="text-2xl font-bold mb-6 text-center text-gray-800">
              Login
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <input
                  type="text"
                  name="username"
                  placeholder="Username"
                  autoComplete="off"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full border-b border-gray-400 bg-transparent px-2 py-2 focus:outline-none focus:border-blue-500 text-sm"
                  required
                />
              </div>

              <div className="mb-4">
                <input
                  type="password"
                  name="password"
                  placeholder="Password"
                  autoComplete="off"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full border-b border-gray-400 bg-transparent px-2 py-2 focus:outline-none focus:border-blue-500 text-sm"
                  required
                />
              </div>

              <div className="flex justify-between items-center text-sm mb-4">
                <label className="flex items-center">
                  <input type="checkbox" className="mr-2" />
                  Remember Me
                </label>
              </div>

              <button
                type="submit"
                className="w-full bg-neutral-800 text-white py-2 rounded-md hover:bg-gray-500 transition text-sm"
              >
                Login
              </button>

              {/* Message Box */}
              {message && (
                <div
                  className={`mt-4 text-center text-sm px-4 py-2 rounded-md transition-all duration-300 ${
                    messageType === "success"
                      ? "bg-green-100 text-green-800 border border-green-300"
                      : "bg-red-100 text-red-800 border border-red-300"
                  }`}
                >
                  {message}
                </div>
              )}
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
