import Sidebar from "@/components/Sidebar"
import Topbar from "@/components/Header"
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
