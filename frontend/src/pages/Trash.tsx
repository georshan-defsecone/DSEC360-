import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"
import Dashboard from "@/pages/Dashboard"


export default function Trash() {
  return (
    <>
        <div className="flex h-screen text-black">
            <Sidebar settings={false} scanSettings={false} homeSettings={true} />
        <div className="flex-1 flex flex-col ml-64">
            <Header title="Trash" />
        <div className="p-4 overflow-auto max-h-[calc(100vh-100px)]">
        
        </div>
      </div>
    </div>  

    </>
  )
}
