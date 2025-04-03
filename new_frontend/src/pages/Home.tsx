import Header from "../components/Header";
import Sidebar from "../components/Sidebar";
const Home: React.FC = () => {
  return (
    <div className="flex">
      {/* Sidebar */}
      <Header />
      <Sidebar />
      {/* Main Content */}
      <main className="p-6 mt-20 ml-60">
        <h1 className="text-2xl">Welcome to the Home Page</h1>
      </main>
    </div>
  );
};

export default Home;
