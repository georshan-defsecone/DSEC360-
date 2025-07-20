import { useEffect, useState, useCallback } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import api from "../api";

import Header from "@/components/Header";
import Sidebar from "@/components/Sidebar";
import ScanPieChart from "@/components/ScanPieChart";

import { Card, CardContent } from "@/components/ui/card";
import ReactECharts from "echarts-for-react";
import { UploadCloud } from "lucide-react";

// Define interfaces for better type safety, reflecting backend serializer output
interface ProjectScanItem {
    scan_id: string;
    scan_name: string;
    scan_author: string;
    scan_status: string; // e.g., "complete", "Pending", "failed"
    scan_type: string; // e.g., "Configuration Audit"
    scan_data: any; // Raw scan configuration JSON
    scan_output: any; // Raw scan output JSON
    scan_time: string; // ISO datetime string
    trash: boolean;
    project: string; // Project ID (FK)
    project_name: string; // Project Name (from source field in serializer)
    scan_result_version: number; // Latest version number for this scan

    // The backend's ScanSerializer.parsed_latest_scan_result field, which is a list of audit items
    parsed_latest_scan_result: AuditResultItem[]; 
    
    // These fields from the serializer are also available but not used directly on this page for table/chart
    available_result_versions?: string[]; // Optional, as it's not strictly needed here
    parsed_result_versions_data?: { [versionKey: string]: AuditResultItem[] | string | null }; // Optional
}

interface AuditResultItem {
    // These fields come from the CSV parsing on the backend
    "CIS.NO"?: string;
    Subject?: string;
    Description?: string;
    "Current Settings"?: string | null;
    Status?: string; // Crucial for counting Pass/Fail
    Remediation?: string;
    
    // Include potential other fields from the new JSON format (if it's not fully CSV-parsed or for robustness)
    name?: string; 
    results?: any; 
}

const ProjectScans = () => {
    const { project_id } = useParams<{ project_id: string }>();
    const navigate = useNavigate();

    const [scans, setScans] = useState<ProjectScanItem[]>([]); // Use the new interface
    const [projectName, setProjectName] = useState("");
    const [searchTerm, setSearchTerm] = useState("");
    const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);

    const [scanTypeFilters, setScanTypeFilters] = useState<string[]>([]);
    const [selectedScanTypes, setSelectedScanTypes] = useState<string[]>([]);

    const fetchScans = useCallback(async () => {
        try {
            const response = await api.get<ProjectScanItem[]>(`scans/project/${project_id}/`); // Expect array of ProjectScanItem
            setScans(response.data);

            const allTypes = [
                ...new Set(response.data.map((scan: ProjectScanItem) => scan.scan_type)),
            ];
            setScanTypeFilters(allTypes);
            setSelectedScanTypes(allTypes); // Select all by default
        } catch (err) {
            console.error("Failed to fetch scans", err);
        }
    }, [project_id]); // Depend on project_id

    const fetchProjectName = useCallback(async () => {
        try {
            const response = await api.get(`project/${project_id}/`);
            setProjectName(response.data.project_name);
        } catch (err) {
            console.error("Failed to fetch project name", err);
        }
    }, [project_id]); // Depend on project_id

    useEffect(() => {
        fetchProjectName();
        fetchScans();
    }, [project_id, fetchProjectName, fetchScans]); // Add fetchProjectName and fetchScans to dependencies

    const toggleScanType = useCallback((type: string) => {
        setSelectedScanTypes((prev) =>
            prev.includes(type) ? prev.filter((t) => t !== type) : [...prev, type]
        );
    }, []); // No external dependencies

    const goToScan = useCallback((scanName: string) => {
        navigate(
            `/scan/scanresult/${encodeURIComponent(projectName)}/${encodeURIComponent(
                scanName
            )}`
        );
    }, [navigate, projectName]); // Depend on navigate and projectName

    // --- Helper to deduce status for Bar Graph ---
    const getStatusForBarGraph = useCallback((item: AuditResultItem): string => {
        if (item.Status) { // Prioritize 'Status' field from backend's CSV parsing
            return item.Status.toLowerCase().trim();
        }
        // Fallback logic if 'Status' is not directly present (e.g., from raw JSON)
        if (item.name?.includes("All_checks_passed_Scored")) return "pass";
        if (item.results === null) return "fail";
        if (typeof item.results === 'string' && item.results.includes("ERROR:")) return "fail";
        
        // Add more specific rules if needed
        return "unknown"; 
    }, []); // No external dependencies, it's a pure function based on item


    // --- MOVED: Calculation of scanTypeCounts and scanBarGraphData ---
    // These calculations must be inside the component body, but before JSX,
    // and they will re-run when `scans` or `selectedScanTypes` changes.
    const scanTypeCounts = scans.reduce((acc, scan) => {
        acc[scan.scan_type] = (acc[scan.scan_type] || 0) + 1;
        return acc;
    }, {} as Record<string, number>);

    const scanBarGraphData = scans
        .filter(
            (scan) =>
                // Check if complianceCategory exists before accessing it
                scan.scan_data?.complianceCategory && 
                (selectedScanTypes.length === 0 ||
                    selectedScanTypes.includes(scan.scan_type))
        )
        .map((scan) => {
            // Access the parsed_latest_scan_result for the bar graph
            const results = scan.parsed_latest_scan_result || []; 
            
            const counts = results.reduce(
                (acc: { Passed: number; Failed: number }, item: AuditResultItem) => {
                    const status = getStatusForBarGraph(item); 
                    if (status === "pass") acc.Passed += 1;
                    else if (status === "fail") acc.Failed += 1;
                    return acc;
                },
                { Passed: 0, Failed: 0 }
            );

            return {
                name: `${scan.scan_data.complianceCategory} (${scan.scan_name})`,
                Passed: counts.Passed,
                Failed: counts.Failed,
            };
        });
    // --- END MOVED CALCULATIONS ---

    const chartHeight = 400; // Fixed height for consistency

    const barChartOption = {
        tooltip: {
            trigger: "axis",
            axisPointer: { type: "shadow" },
            backgroundColor: "#fff",
            borderColor: "#ccc",
            borderWidth: 1,
            textStyle: { color: "#333" },
        },
        legend: {
            data: ["Passed", "Failed"],
            top: 0,
            right: 10,
            left: "center",
            textStyle: { fontWeight: "bold" },
        },
        grid: {
            left: 50,
            right: 30,
            bottom: 50,
            top: 50,
            containLabel: true,
        },
        xAxis: {
            type: "category",
            data: scanBarGraphData.map((d) => d.name),
            axisLabel: {
                fontSize: 10,
                rotate: 45,
                overflow: "truncate",
                formatter: (val: string) =>
                    val.length > 30 ? val.slice(0, 27) + "..." : val,
            },
        },
        yAxis: {
            type: "value",
            axisLabel: {
                fontSize: 12,
                color: "#444",
            },
            splitLine: {
                lineStyle: { color: "#f0f0f0" },
            },
        },
        series: [
            {
                name: "Passed",
                type: "bar",
                stack: "status",
                data: scanBarGraphData.map((d) => d.Passed),
                label: {
                    show: true,
                    position: "top",
                    color: "#22c55e",
                    fontWeight: "bold",
                },
                itemStyle: {
                    color: "#4ade80",
                },
                barWidth: 30,
            },
            {
                name: "Failed",
                type: "bar",
                stack: "status",
                data: scanBarGraphData.map((d) => d.Failed),
                label: {
                    show: true,
                    position: "top",
                    color: "#ef4444",
                    fontWeight: "bold",
                },
                itemStyle: {
                    color: "#f87171",
                },
                barWidth: 30,
            },
        ],
    };

    const filteredScans = scans.filter(
        (scan) =>
            (selectedScanTypes.length === 0 ||
                selectedScanTypes.includes(scan.scan_type)) &&
            `${scan.scan_name} ${scan.scan_author} ${scan.scan_status}`
                .toLowerCase()
                .includes(searchTerm.toLowerCase())
    );

    const formatDateWithSuffix = useCallback((date: Date) => {
        const day = date.getDate();
        const month = date.toLocaleString("en-GB", { month: "long" });
        const suffix =
            day % 10 === 1 && day !== 11
                ? "st"
                : day % 10 === 2 && day !== 12
                ? "nd"
                : day % 10 === 3 && day !== 13
                ? "rd"
                : "th";
        return `${day}${suffix} ${month}`;
    }, []);

    return (
        <div className="flex h-screen text-black">
            <Sidebar settings={false} scanSettings={false} homeSettings={true} />
            <div className="flex-1 flex flex-col ml-64 pt-20 bg-gray-50">
                <Header title={projectName}>
                    <Link
                        to="/scan"
                        className="text-sm text-blue-600 font-medium ml-4 hover:underline"
                    >
                        + New Scan
                    </Link>
                </Header>

                <div className="w-full px-6 mt-4 space-y-8">
                    {uploadSuccess && (
                        <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-2 rounded text-sm">
                            {uploadSuccess}
                        </div>
                    )}

                    <div className="bg-white border border-gray-200 shadow p-4 relative">
                        <h3 className="text-lg font-semibold text-gray-800 mb-2">
                            Scan Results Overview
                        </h3>

                        <div className="mb-4 flex flex-wrap gap-3">
                            {scanTypeFilters.map((type) => (
                                <label
                                    key={type}
                                    className="flex items-center text-sm space-x-1"
                                >
                                    <input
                                        type="checkbox"
                                        checked={selectedScanTypes.includes(type)}
                                        onChange={() => toggleScanType(type)}
                                        className="accent-blue-600"
                                    />
                                    <span>{type}</span>
                                </label>
                            ))}
                        </div>

                        <ReactECharts
                            option={barChartOption}
                            style={{ height: `${chartHeight}px`, width: "100%" }}
                            notMerge={true}
                            lazyUpdate={true}
                        />
                    </div>

                    <div className="flex gap-6">
                        <Card className="w-2/3 shadow-lg border rounded-none border-gray-200 bg-white">
                            <CardContent className="p-5">
                                <div className="flex justify-between items-center mb-2">
                                    <h2 className="text-xl font-semibold text-gray-800">
                                        Scan List
                                    </h2>

                                    <input
                                        type="text"
                                        placeholder="Search..."
                                        value={searchTerm}
                                        onChange={(e) => setSearchTerm(e.target.value)}
                                        className="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                                    />
                                </div>

                                <div className="border-b border-gray-300 mb-4" />

                                <div className="relative">
                                    <div className="overflow-y-auto h-[410px]">
                                        <table className="table-fixed w-full text-sm border-collapse">
                                            <thead className="sticky top-0 z-10 bg-gray-200 text-gray-700 border-b border-gray-400">
                                                <tr>
                                                    <th className="w-[30%] text-left px-4 py-2">
                                                        Scan Name
                                                    </th>
                                                    <th className="w-[25%] text-left px-4 py-2">
                                                        Author
                                                    </th>
                                                    <th className="w-[20%] text-left px-4 py-2">
                                                        Created At
                                                    </th>
                                                    <th className="w-[25%] text-left px-4 py-2">
                                                        Status
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {filteredScans.length === 0 ? (
                                                    <tr>
                                                        <td colSpan={4} className="text-center py-4">
                                                            No matching scans found.
                                                        </td>
                                                    </tr>
                                                ) : (
                                                    filteredScans.map((scan, i) => {
                                                        const isUploadRequired =
                                                            scan.scan_data?.auditMethod === "agent" &&
                                                            !scan.parsed_latest_scan_result?.length;

                                                        return (
                                                            <tr
                                                                key={scan.scan_id}
                                                                onClick={() => {
                                                                    if (!isUploadRequired)
                                                                        goToScan(scan.scan_name);
                                                                }}
                                                                className={`border-b border-gray-100 ${
                                                                    isUploadRequired
                                                                        ? "cursor-default"
                                                                        : "cursor-pointer hover:bg-gray-100"
                                                                } ${i % 2 === 0 ? "bg-white" : "bg-gray-50"}`}
                                                            >
                                                                <td className="py-3 px-4 font-medium border-none">
                                                                    {scan.scan_name}
                                                                </td>
                                                                <td className="py-3 px-4 border-none">
                                                                    {scan.scan_author}
                                                                </td>
                                                                <td className="py-3 px-4 border-none">
                                                                    {scan.scan_time ? (
                                                                        <>
                                                                            {formatDateWithSuffix(
                                                                                new Date(scan.scan_time)
                                                                            )}
                                                                            ,{" "}
                                                                            {new Date(
                                                                                scan.scan_time
                                                                            ).toLocaleTimeString("en-GB", {
                                                                                hour: "2-digit",
                                                                                minute: "2-digit",
                                                                                hour12: false,
                                                                            })}
                                                                        </>
                                                                    ) : (
                                                                        "N/A"
                                                                    )}
                                                                </td>
                                                                <td className="py-3 px-4 border-none flex items-center gap-2 relative">
                                                                    <span>{scan.scan_status}</span>
                                                                    {isUploadRequired && (
                                                                        <>
                                                                            <input
                                                                                type="file"
                                                                                accept="*"
                                                                                id={`file-upload-${scan.scan_id}`}
                                                                                style={{ display: "none" }}
                                                                                onChange={async (e) => {
                                                                                    e.stopPropagation();
                                                                                    const file = e.target.files?.[0];
                                                                                    if (!file) return;

                                                                                    const formData = new FormData();
                                                                                    formData.append("file", file);
                                                                                    formData.append("scan_id", scan.scan_id);

                                                                                    try {
                                                                                        const res = await api.post(
                                                                                            `/scans/upload-result/${scan.scan_id}/`,
                                                                                            formData,
                                                                                            {
                                                                                                headers: {
                                                                                                    "Content-Type": "multipart/form-data",
                                                                                                },
                                                                                            }
                                                                                        );

                                                                                        setUploadSuccess("Scan result uploaded successfully ✅");
                                                                                        fetchScans();
                                                                                        setTimeout(() => setUploadSuccess(null), 3000);
                                                                                    } catch (err) {
                                                                                        console.error("Upload failed:", err);
                                                                                        if (err.response && err.response.data && err.response.data.error) {
                                                                                            alert(`Upload failed: ${err.response.data.error}`);
                                                                                        } else {
                                                                                            alert("Error uploading file.");
                                                                                        }
                                                                                    }
                                                                                }}
                                                                            />

                                                                            <button
                                                                                title="Upload Result"
                                                                                className="text-blue-600 hover:text-blue-800 cursor-pointer transition-all duration-200"
                                                                                onClick={(e) => {
                                                                                    e.stopPropagation();
                                                                                    const input = document.getElementById(
                                                                                        `file-upload-${scan.scan_id}`
                                                                                    ) as HTMLInputElement;
                                                                                    input?.click();
                                                                                }}
                                                                            >
                                                                                <UploadCloud className="w-5 h-5" />
                                                                            </button>
                                                                        </>
                                                                    )}
                                                                </td>
                                                            </tr>
                                                        );
                                                    })
                                                )}
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>

                        <div className="w-1/3 bg-white border border-gray-200 shadow flex items-center justify-center">
                            <ScanPieChart
                                data={scanTypeCounts}
                                selectedTypes={selectedScanTypes}
                                onTypeClick={toggleScanType}
                            />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ProjectScans;