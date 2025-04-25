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
                    <li key={index} className="inline-flex items-center">
                        {index > 0 && (
                            <ChevronRight className="w-4 h-4 text-gray-400 mx-1"/>
                        )}
                        <span className={`inline-flex items-center text-sm font-medium ${
                            currentPage === index + 1 ? "text-black font-semibold" : "text-gray-500"
                        }`}>{page}</span>
                    </li>
                ))}
            </ol>
        </nav>
    )
}

export default Breadcrumbs;