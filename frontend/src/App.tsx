import './App.css'
import DashBoard from './pages/dashboard'
import {BrowserRouter as Router , Routes, Route } from 'react-router-dom';
import AssetDiscovery from './pages/assetdiscovery';
import PortsAndServiceEnumeration from './pages/portsandserviceenumeration';
import Settings from './pages/settings';
import SettingsAbout from './pages/settingsAbout';
import SettingsAdvanced from './pages/settingsAdvanced';
import SettingsMyAccount from './pages/settingsMyAccount';
import SettingsNotification from './pages/settingsNotification';
import SettingsPasswordmgmt from './pages/settingsPasswordmgmt';
import SettingsProxyServer from './pages/settingsProxyServer';
import SettingsSMTP from './pages/settingsSMTP';
import SettingsUser from './pages/settingsUser';


function App() {
  return(

     <Router>
      <Routes>
        <Route path="/assetdiscovery" element={<AssetDiscovery />} />
        <Route path="/portsandserviceenumeration" element={<PortsAndServiceEnumeration />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/" element={<DashBoard />} />
        <Route path="/settings/about" element={<SettingsAbout />} />
        <Route path="/settings/advanced" element={<SettingsAdvanced />} />
        <Route path="/settings/proxyserver" element={<SettingsProxyServer />} />
        <Route path="/settings/smtpserver" element={<SettingsSMTP />} />
        <Route path="/settings/passwordmgmt" element={<SettingsPasswordmgmt />} />
        <Route path="/settings/notifications" element={<SettingsNotification />} />
        <Route path="/settings/myaccount" element={<SettingsMyAccount />} />
        <Route path="/settings/user" element={<SettingsUser />} />
      </Routes>
     </Router>
  )

}

export default App
