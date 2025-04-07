import React from "react";

const Login: React.FC = () => {
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
          <h1 className="text-lg font-semibold text-white">Defsecone 360+</h1>
        </div>

        {/* Right Panel */}
        <div className="md:w-[70%] w-full flex items-center justify-center p-6 bg-white">
          <div className="w-full max-w-xs">
            <h2 className="text-2xl font-bold mb-6 text-center text-gray-800">
              Login
            </h2>
            <form>
              {/* Email Field */}
              <div className="mb-4">
                <input
                  type="email"
                  name="email"
                  placeholder="Email Address"
                  autoComplete="off"
                  className="w-full border-b border-gray-400 bg-transparent px-2 py-2 focus:outline-none focus:border-blue-500 text-sm"
                  required
                />
              </div>

              {/* Password Field */}
              <div className="mb-4">
                <input
                  type="password"
                  name="password"
                  placeholder="Password"
                  autoComplete="off"
                  className="w-full border-b border-gray-400 bg-transparent px-2 py-2 focus:outline-none focus:border-blue-500 text-sm"
                  required
                />
              </div>

              {/* Remember Me + Forgot Password */}
              <div className="flex justify-between items-center text-sm mb-4">
                <label className="flex items-center">
                  <input type="checkbox" className="mr-2" />
                  Remember Me
                </label>
                <a href="#" className="text-blue-500 hover:underline">
                  Forgot Password?
                </a>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                className="w-full bg-blue-600 text-white py-2 rounded-md hover:bg-blue-700 transition text-sm"
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
