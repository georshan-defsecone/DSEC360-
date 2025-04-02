import { useState } from 'react';
import HeaderBar from '../components/HeaderBar'
import Sidebar from '../components/Sidebar'

function Dashboard() {

    const [, setActivePage] = useState('Dashboard')

  return (
    <div>
      <div className="app-container">
            <HeaderBar />
            <div className="layout">
                <Sidebar setActivePage={setActivePage} />
                
            </div>
        </div>
    </div>
  )
}

export default Dashboard
