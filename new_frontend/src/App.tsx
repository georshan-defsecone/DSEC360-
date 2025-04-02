import { Button } from "@/components/ui/button";4
import Sidebar from "./components/Sidebar";
import Header from "./components/header";
function App() {
  return (
    <div>
      <Header />
      <div className="flex">
        <Sidebar />
        <main className="flex-1 p-6">
          <h1 className="text-2xl">Welcome to My Website</h1>
        </main>
      </div>
      {/*<Button>Click me</Button> We can also use the <Button name="Click me">*/}
    </div>
  );
}

export default App;
