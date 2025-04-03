import { Button } from "./button"
import { Link } from "react-router-dom"

const CompromiseAssessment = () => {
    return (
        <>
            <div className="mb-4">
                <h3 className="font-bold text-black text-lg border-b-2 border-neutral-400 text-center mb-2">Compromise Assessment</h3>
                <ul className="list-none flex flex-col gap-2 items-start">
                    <li><Button variant="link" className="p-2"><Link to="compromise-assessment/windows" className="text-base">Windows</Link></Button></li>
                    <li><Button variant="link" className="p-2"><Link to="compromise-assessment/linux" className="text-base">Linux</Link></Button></li>
                </ul>
            </div>
        </>
    )
}

export default CompromiseAssessment