import { Link } from "react-router-dom"

const CompromiseAssessment = () => {
    return (
        <>
            <div className="mb-4">
                <h3 className="font-bold text-black text-lg border-b-2 border-neutral-400 text-center mb-2">Compromise Assessment</h3>
                <ul className="list-none flex flex-col gap-2 items-start">
                    <li className="hover:bg-gray-200 block w-full p-1 rounded"><Link to="compromise-assessment/windows" className="text-base">Windows</Link></li>
                    <li className="hover:bg-gray-200 block w-full p-1 rounded"><Link to="compromise-assessment/linux" className="text-base">Linux</Link></li>
                </ul>
            </div>
        </>
    )
}

export default CompromiseAssessment