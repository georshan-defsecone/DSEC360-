import './App.css';
import Dashboard from "./pages/Dashboard";
import Login from "./pages/Login";
import Settings from "./pages/Settings"
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { Routes , Route } from 'react-router-dom';

function App() {
  return (
    <div className='APP'>
        <Routes>
          <Route path='/' element={<Dashboard/>}/>
          <Route path='/auth/login' element={<Login/>}/>
          <Route path='/settings' element={<Settings/>}/>

        </Routes>
    </div>
  );
}

export default App;
