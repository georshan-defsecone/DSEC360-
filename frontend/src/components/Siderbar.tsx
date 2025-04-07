import { Settings } from "lucide-react"

export default function Sidebar() {
  return (
    <div className="w-60 h-screen p-6 flex flex-col ">
      <div className="flex-1"> 
        <div className="flex items-center m-3 mb-10">
          <img src="logo.png" alt="Logo" className="w-10"/>
          <h2 className="text-2xl font-bold ml-3 ">DES360+</h2>
        </div>

        <nav className="space-y-10 flex flex-col">
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
            My Projects
          </button>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
            All Projects
          </button>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
            Results
          </button>
          <button className="block w-full text-left px-4 py-2 rounded hover:bg-slate-400 font-medium">
            Trash
          </button>
        </nav>
      </div>

      <div className="flex flex-start items-center">
          <Settings className="w-5 h-5 " />
      </div>
    </div>
  )
}