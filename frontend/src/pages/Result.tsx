import Sidebar from "@/components/Sidebar"
import Header from "@/components/Header"


export default function Result() {
  return (
    <>
        <div className="flex h-screen text-black pt-18">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64">
        <Header title="Results" />
        <div className="p-4 overflow-auto max-h-[calc(100vh-100px)]">
          Results come here
        </div>
      </div>
    </div>  

    </>
  )
}
