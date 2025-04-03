import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import Profile from "./pages/Profile";
import Team from "./pages/Team";
import Scan from "./pages/Scan";
import LoginPage from "./components/Login";

const App: React.FC = () => {
  return (
    <Router>
      <Routes>
        {/* Default route set to LoginPage */}
        <Route path="/" element={<LoginPage />} />
        <Route path="/home" element={<Home />} />
        <Route path="/profile" element={<Profile />} />
        <Route path="/settings" element={<Scan />} />
        <Route path="/team" element={<Team />} />
      </Routes>
    </Router>
  );
};

export default App;
