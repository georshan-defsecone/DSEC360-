import React, { useState } from "react";
import { useNavigate } from "react-router-dom";

const Login: React.FC = () => {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

const navigate=useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const response = await fetch("http://localhost:8000/api/token/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          username: username,
          password: password,
        }),
      });

      const data = await response.json();

      if (response.ok) {
        // Save tokens (you can use localStorage/sessionStorage)
        localStorage.setItem("access", data.access);
        localStorage.setItem("refresh", data.refresh);
        alert("Login Successful!");
        navigate("/")
      } else {
        alert("Invalid credentials");
        console.error(data);
      }
    } catch (error) {
      console.error("Error:", error);
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
                  placeholder="username"
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
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
