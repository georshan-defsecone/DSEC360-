import axios from "axios";
import { useState } from "react";
import { Input } from "./ui/input";

type UploadStatus = "idle" | "uploading" | "success" | "error";

const FileUploader = () => {
    const [file, setFile] = useState<File | null>(null)
    const [status, setStatus] = useState<UploadStatus>("idle")

    function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
        if(e.target.files) {
            setFile(e.target.files[0])
        }
    }

    async function uploadFile(){
        if(!file) return
        setStatus("uploading")

        const formData = new FormData()
        formData.append("file", file)

        try {
            await axios.post("http://localhost:8000/api/scans/upload/", formData, {
                headers: {
                    "Content-Type": "multipart/form-data",
                },
            })
            setStatus("success")
        } catch {
            setStatus("error")
        }
    }

    return(
        <div className="space-y-2">
            <Input type="file" onChange={handleFileChange}/>
            {file && status !== "uploading" &&
                <button onClick={uploadFile}>upload</button>
            }

            {file && status === "success" &&
                <p className="text-green-500">File uploaded successfully!</p>
            }

            {file && status === "error" &&
                <p className="text-red-500">Error uploading file!</p>
            }
        </div>
    )
}

export default FileUploader;