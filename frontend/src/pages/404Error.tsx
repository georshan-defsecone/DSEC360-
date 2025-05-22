import { Link } from "react-router-dom"

const Error404 = () => {
    return(
        <>
            <div className="flex flex-col gap-4 justify-center items-center h-screen w-screen pb-32">
                <h1 className="font-bold text-6xl">404 Error</h1>
                <h2 className="font-semibold text-5xl">Page not found, go to <Link to={"/"} className="text-decoration-line: underline">home</Link>?</h2>
            </div>
        </>
    )
}

export default Error404