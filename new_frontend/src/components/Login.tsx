import { useState } from "react";
import { useNavigate } from "react-router-dom";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>): void => {
    e.preventDefault();
    // Perform authentication logic here
    const isAuthenticated = true; // Replace with actual authentication check
    if (isAuthenticated) {
      navigate("/home");
    } else {
      // Handle authentication failure (e.g., show error message)
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-white p-4">
      <div
        className="p-6 rounded-2xl shadow-lg w-full max-w-md"
        style={{ backgroundColor: "#d3d3d3" }}
      >
        <h2 className="text-2xl font-bold text-center text-gray-800">Login</h2>
        <form onSubmit={handleSubmit} className="mt-4">
          {/* Email Input */}
          <div>
            <label className="block text-gray-700 font-medium">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2 border rounded-lg mt-1 focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          {/* Password Input */}
          <div className="mt-3">
            <label className="block text-gray-700 font-medium">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2 border rounded-lg mt-1 focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          {/* Submit Button */}
          <button
            type="submit"
            className="w-full mt-4 bg-blue-500 text-white py-2 rounded-lg hover:bg-blue-600 transition"
          >
            Login
          </button>
        </form>
      </div>
    </div>
  );
}
