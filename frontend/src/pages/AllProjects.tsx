import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"


export default function AllProjects() {
  return (
    <>
        <div className="flex h-screen text-black">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64">
        <Header title="All Projects" />
        <div className="p-4 overflow-auto max-h-[calc(100vh-100px)]">
        Allporjects card goes here
        </div>
      </div>
    </div>  

    </>
  )
}
