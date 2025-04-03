import Header from "../components/Header";
import SettingSide from "../components/SettingSide";

const Scan: React.FC = () => {
  return (
    <div className="h-screen w-full bg-gray-100">
      {/* Fixed Header */}
      <Header />

      {/* Layout Wrapper */}
      <div className="flex pt-16">
        {/* Sidebar - Stays below Header */}
        <aside className="w-60 h-screen shadow-lg fixed left-0">
          <SettingSide />
        </aside>

        {/* Main Content - Adjusted to not overlap Sidebar */}
        <main className="flex-1 p-6 ml-60">
          <h1 className="text-2xl font-semibold">Welcome to the Scan Page</h1>
          <p className="text-gray-700 mt-2">
            Perform vulnerability scans efficiently with DSEC360+.
          </p>
        </main>
      </div>
    </div>
  );
};

export default Scan;
