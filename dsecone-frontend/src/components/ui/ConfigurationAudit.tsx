import { Link } from "react-router-dom"

const ConfigurationAudit = () => {
    return (
        <>
            <div className="mb-4">
                <h3 className="font-bold text-black text-lg border-b-2 border-neutral-400 text-center mb-2">Configuration Audit</h3>
                <ul className="list-none flex flex-col gap-2 items-start ml-0">
                    <li className="hover:bg-gray-200 block w-full p-1 rounded"><Link to="/config-audit/windows" className="text-base">Windows</Link></li>
                    <li className="hover:bg-gray-200 block w-full p-1 rounded"><Link to="/config-audit/linux" className="text-base">Linux</Link></li>
                    <li className="hover:bg-gray-200 block w-full p-1 rounded"><Link to="/config-audit/network-devices" className="text-base">Network/Security Devices</Link></li>
                </ul>
            </div>
        </>
    )
}

export default ConfigurationAudit