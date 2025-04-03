import Header from "../components/ui/Header"
import Sidebar from "../components/ui/Sidebar"

function Ports() {
  return (
    <>
      <Header></Header>
      <div className="flex gap-4">
          <Sidebar>
          </Sidebar>
          <main className="ml-80 mt-[6rem]">
            <h1 className="text-black text-2xl font-bold">This is the Ports and Service Enumeration page</h1>
          </main>
      </div>
    </>
  )
}

export default Ports
