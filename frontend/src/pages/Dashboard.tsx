import Sidebar from "@/components/Siderbar"
import Topbar from "@/components/Topbar"
import DashboardContent from "@/components/DashboardContent"

function Dashboard() {
  return (
    <div className="flex h-screen text-black">
      <Sidebar />
      <div className="flex-1 flex flex-col">
        <Topbar />
        <div className="p-4">
          <DashboardContent />
        </div>
      </div>
    </div>
  )
}

export default Dashboard
