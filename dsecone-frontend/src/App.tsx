import Header from "./components/ui/Header"
import Sidebar from "./components/ui/Sidebar"

function Home() {
  return (
    <>
      <Header></Header>
      <div className="flex gap-4">
          <Sidebar>
          </Sidebar>
          <main className="ml-70 mt-20">
            <h1>This is the main page</h1>
          </main>
      </div>
    </>
  )
}

export default Home
