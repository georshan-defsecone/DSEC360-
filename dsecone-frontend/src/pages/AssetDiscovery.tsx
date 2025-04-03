import Header from "../components/ui/Header"
import Sidebar from "../components/ui/Sidebar"

function AssetDiscovery() {
  return (
    <>
      <Header></Header>
      <div className="flex gap-4">
          <Sidebar>
          </Sidebar>
          <main className="ml-80 mt-[6rem]">
            <h1 className="text-2xl font-bold">This is the Asset Discovery Page</h1>
          </main>
      </div>
    </>
  )
}

export default AssetDiscovery
