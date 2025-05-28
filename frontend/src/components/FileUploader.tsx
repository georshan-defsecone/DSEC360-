import { useState } from "react";
import { Input } from "./ui/input";

interface FileUploaderProps {
    onFileParsed: (data: string[]) => void;
}

const FileUploader = ({ onFileParsed }: FileUploaderProps) => {
    const [file, setFile] = useState<File | null>(null);

    function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
        if (e.target.files && e.target.files[0]) {
            const selectedFile = e.target.files[0];
            setFile(selectedFile);
            parseCSVfile(selectedFile);
        }
    }

    function parseCSVfile(file: File) {
        const reader = new FileReader();
        reader.onload = (e) => {
            const text = e.target?.result as string;
            const lines = text
                .split("\n")
                .map((line) => line.trim())
                .filter(Boolean);
            onFileParsed(lines);
        };
        reader.readAsText(file);
    }

    return (
        <div className="ml-4 flex">
            <input
                type="file"
                id="fileUpload"
                onChange={handleFileChange}
                className="hidden"
            />

            {/* Styled label as the visible "button" */}
            <label
                htmlFor="fileUpload"
                className="inline-block text-sm font-medium text-white bg-black px-4 py-2 rounded cursor-pointer hover:bg-gray-200 hover:text-black transition-colors"
            >
                Upload File
            </label>
        </div>
    );
};

export default FileUploader;
