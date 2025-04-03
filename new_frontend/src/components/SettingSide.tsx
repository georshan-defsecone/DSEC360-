import { Link } from "react-router-dom";
import {
  FaCogs,
  FaServer,
  FaLink,
  FaEnvelope,
  FaUserShield,
  FaLock,
  FaUser,
  FaUsers,
} from "react-icons/fa";

const SettingSide = () => {
  return (
    <aside className="w-60 bg-gray-900 text-white h-screen fixed top-20 left-0 p-4 shadow-lg">
      <h2 className="text-lg font-bold mb-4 uppercase text-gray-300">
        Settings
      </h2>
      <nav className="space-y-2">
        <Link
          to="/about"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaCogs className="mr-2" />
          About
        </Link>
        <Link
          to="/advanced"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaCogs className="mr-2" />
          Advanced
        </Link>
        <Link
          to="/proxy"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaServer className="mr-2" />
          Proxy Server
        </Link>
        <Link
          to="/remote"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaLink className="mr-2" />
          Remote Link
        </Link>
        <Link
          to="/smtp"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaEnvelope className="mr-2" />
          SMTP Server
        </Link>
        <Link
          to="/custom-ca"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaUserShield className="mr-2" />
          Custom CA
        </Link>
        <Link
          to="/password"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaLock className="mr-2" />
          Password Mgmt
        </Link>
        <Link
          to="/scanner-health"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaServer className="mr-2" />
          Scanner Health
        </Link>
        <Link
          to="/notifications"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaEnvelope className="mr-2" />
          Notifications
        </Link>
      </nav>

      <h2 className="text-lg font-bold mt-6 mb-4 uppercase text-gray-300">
        Accounts
      </h2>
      <nav className="space-y-2">
        <Link
          to="/my-account"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaUser className="mr-2" />
          My Account
        </Link>
        <Link
          to="/users"
          className="flex items-center p-2 hover:bg-gray-800 rounded-md"
        >
          <FaUsers className="mr-2" />
          Users
        </Link>
      </nav>
    </aside>
  );
};

export default SettingSide;
