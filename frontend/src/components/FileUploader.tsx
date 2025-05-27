import { useState } from "react";
import { Input } from "./ui/input";

interface  FileUploaderProps {
    onFileParsed: (data:string[]) => void
}

const FileUploader = ({onFileParsed}: FileUploaderProps) => {
    const [file, setFile] = useState<File | null>(null)

    function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
        if(e.target.files && e.target.files[0]) {
            const selectedFile = e.target.files[0]
            setFile(selectedFile)
            parseCSVfile(selectedFile)
        }
    }

    function parseCSVfile(file: File) {
        const reader = new FileReader()
        reader.onload = (e) => {
            const text = e.target?.result as string;
            const lines = text.split('\n').map(line => line.trim()).filter(Boolean)
            onFileParsed(lines)
        }
        reader.readAsText(file)
    }

    return(
        <div className="ml-4">
            <Input type="file" onChange={handleFileChange} className="w-60" placeholder="Choose File"/>
        </div>
    )
}

export default FileUploader;