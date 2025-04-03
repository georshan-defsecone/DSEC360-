import Header from "../components/Header";
import Sidebar from "../components/Sidebar";
const Profile: React.FC = () => {
  return (
    <main className="p-6 mt-20 ml-60">
      {/* Sidebar */}
      <Header />
      <Sidebar />
      {/* Main Content */}
      <h1 className="text-2xl">Welcome to the Profile Page</h1>
    </main>
  );
};

export default Profile;
