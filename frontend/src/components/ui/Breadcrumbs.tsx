import { ChevronRight } from "lucide-react";

interface BreadcrumbProps {
    currentPage: number;
    pages: string[];
}

const Breadcrumbs = ({currentPage, pages}: BreadcrumbProps) => {
    return (
        <nav className="flex" aria-label="Breadcrumb">
            <ol className="inline-flex items-center space-x-1 md:space-x-2">
                {pages.map((page, index) => (
                    <li key={index} className="inline-flex items-center text-sm">
                        {index > 0 && (
                            <ChevronRight className="w-4 h-4 text-gray-400 mx-1"/>
                        )}
                        <span className={`inline-flex items-center font-medium  ${
                            currentPage === index + 1 ? "text-black font-bold" : "text-gray-400"
                        }`}>{page}</span>
                    </li>
                ))} 
            </ol>
        </nav>
    )
}

export default Breadcrumbs;