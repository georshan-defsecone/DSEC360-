import { useParams } from "react-router-dom";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import api from "../api";
import { useEffect, useState, useCallback, useRef, DragEvent, useMemo } from "react";
import { CircleCheck, CircleX, MoreVertical, Check, X, Download, RefreshCw, UploadCloud, File as FileIcon, AlertTriangle } from "lucide-react";
import { Card } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import React from "react";
import ScanPieChart from "@/components/ScanPieChart";
import { Input } from "@/components/ui/input";

// Define interfaces
interface AuditResultItem {
  "CIS.NO"?: string;
  Subject?: string;
  Description?: string;
  "Current Settings"?: string | null;
  Status?: string;
  Remediation?: string;
  name?: string;
  results?: any;
  status_type?: string;
  script_filename?: string;
  message?: string;
}

interface ScanSummary {
  Passed: number;
  Failed: number;
}

interface ScanDetailsBackend {
  scan_id: string;
  scan_name: string;
  scan_author: string;
  scan_status: string;
  scan_type: string;
  project: string;
  project_name: string;
  scan_data: any;
  scan_output: any;
  scan_time: string;
  trash: boolean;
  scan_result_version: number;
  parsed_latest_scan_result: AuditResultItem[];
  parsed_result_versions_data: { [versionKey: string]: AuditResultItem[] | string | null };
  available_result_versions: string[];
}

type SortDirection = "none" | string;

const ScanResult = () => {
  const { projectName, scanName } = useParams<{
    projectName: string;
    scanName: string;
  }>();

  const [summary, setSummary] = useState<ScanSummary>({ Passed: 0, Failed: 0 });
  const [scanDetails, setScanDetails] = useState<ScanDetailsBackend | null>(null);
  const [displayAuditResults, setDisplayAuditResults] = useState<AuditResultItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>("");
  const [expandedRows, setExpandedRows] = useState<number[]>([]);
  const [sortDirection, setSortDirection] = useState<SortDirection>("none");
  const [isRescanning, setIsRescanning] = useState(false);
  const [selectedVersionKey, setSelectedVersionKey] = useState<string | null>(null);
  const [uploadMessage, setUploadMessage] = useState<string | null>(null);
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  const [editingValue, setEditingValue] = useState<string>("");

  // --- State for Modals & File Upload ---
  const [showRescanModal, setShowRescanModal] = useState(false);
  const [showDownloadModal, setShowDownloadModal] = useState(false);
  const [fileToUpload, setFileToUpload] = useState<File | null>(null);
  const [isDragging, setIsDragging] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const getStatusForItem = useCallback((item: AuditResultItem): string => {
    if (item.status_type === 'script_generated') {
        return 'SCRIPT_GENERATED';
    }
    if (item.Status) {
        return item.Status.toLowerCase().trim();
    }
    if (item.name?.includes("All_checks_passed_Scored")) return "pass";
    if (item.results === null) return "fail";
    if (typeof item.results === 'string' && item.results.includes("ERROR:")) return "fail";
    if (Array.isArray(item.results) && item.results.length > 0) {
        const firstResult = item.results[0];
        if (firstResult && typeof firstResult === 'object') {
            const value = firstResult.VALUE?.toLowerCase();
            const val = firstResult.value?.toLowerCase();
            const limit = firstResult.LIMIT?.toLowerCase();
            if (item.name?.includes("OS_ROLES") && value === "false") return "pass";
            if (item.name?.includes("SERVER_RELEASE_BANNER") && value === "false") return "pass";
            if (item.name?.includes("SQL92_SECURITY") && value === "true") return "pass";
            if (item.name?.includes("AUDIT_SYS_OPERATIONS") && val === "false") return "fail";
            if (item.name?.includes("PROTOCOL_ERROR_TRACE_ACTION") && value === "trace") return "fail";
            if (item.name?.includes("REMOTE_LOGIN_PASSWORDFILE") && value === "exclusive") return "fail";
            if (item.name?.includes("AUDIT_TRAIL") && value === "none") return "fail";
            if (item.name?.includes("GLOBAL_NAMES") && value === "false") return "fail";
            if (item.name?.includes("SESSIONS_PER_USER") && limit === "unlimited") return "fail";
            if (item.name?.includes("PASSWORD_LIFE_TIME") && limit === "180") return "fail";
            if (item.name?.includes("PASSWORD_GRACE_TIME") && limit === "7") return "fail";
            if (item.name?.includes("PASSWORD_VERIFY_FUNCTION") && limit === "null") return "fail";
            if (item.name?.includes("INACTIVE_ACCOUNT_TIME") && limit === "365") return "fail";
            if (item.name?.includes("SEC_MAX_FAILED_LOGIN_ATTEMPTS") && value === "3") return "pass";
            if (item.name?.includes("SEC_PROTOCOL_ERROR_FURTHER_ACTION") && value === "(drop,3)") return "pass";
            if (item.name?.includes("RESOURCE_LIMIT") && value === "true") return "pass";
            if (item.name?.includes("FAILED_LOGIN_ATTEMPTS") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("PASSWORD_LOCK_TIME") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("PASSWORD_REUSE_MAX") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("PASSWORD_REUSE_TIME") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("All_Default_Passwords_Are_Changed") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("All_Sample_Data_And_Users_Have_Been_Removed") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("AUTHENTICATION_TYPE_Is_Not_Set_to_EXTERNAL") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("SYS_USER_MIG_Has_Been_Dropped") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("No_Public_Database_Links_Exist") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (item.name?.includes("USER_Audit_Option_Is_Enabled") && (item.results === null || (Array.isArray(item.results) && item.results.length === 0))) return "pass";
            if (firstResult.message?.toLowerCase().includes("all checks passed")) return "pass";
            if (item.name?.includes("All_checks_passed_Scored")) return "pass";
        }
    }
    return "unknown";
  }, []);

  const fetchScanData = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const response = await api.get(`/scans/scan-result/${projectName}/${scanName}`);
      const fullScanData: ScanDetailsBackend = response.data;
      const auditResultsForLatest: AuditResultItem[] = fullScanData.parsed_latest_scan_result || [];
      let Passed = 0;
      let Failed = 0;
      auditResultsForLatest.forEach((item: AuditResultItem) => {
        const status = getStatusForItem(item);
        if (status === "pass") Passed++;
        else if (status === "fail") Failed++;
      });
      setScanDetails(fullScanData);
      setDisplayAuditResults(auditResultsForLatest);
      setSelectedVersionKey(`v${fullScanData.scan_result_version}`);
      setSummary({ Passed, Failed });
    } catch (err: any) {
      console.error("Failed to fetch or parse scan result:", err);
      if (err.response) {
        if (err.response.status === 204) {
          setError("No scan result data available for this scan.");
        } else if (err.response.data && typeof err.response.data.error === 'string') {
          setError(err.response.data.error);
        } else {
          setError(`Server Error: ${err.response.status} - ${err.response.statusText}`);
        }
      } else {
        setError("Failed to fetch scan result. Network error or invalid response.");
      }
    } finally {
      setLoading(false);
      setIsRescanning(false);
    }
  }, [projectName, scanName, getStatusForItem]);

  useEffect(() => {
    if (!projectName || !scanName) {
      setError("Missing scan information.");
      setLoading(false);
      return;
    }
    fetchScanData();
  }, [projectName, scanName, fetchScanData]);

  const handleVersionChange = useCallback((versionKey: string) => {
    if (!scanDetails || !scanDetails.parsed_result_versions_data) return;
    const versionData = scanDetails.parsed_result_versions_data[versionKey];
    let newDisplayResults: AuditResultItem[] = [];
    if (Array.isArray(versionData)) {
      newDisplayResults = versionData;
    } else if (versionData !== undefined && versionData !== null) {
      newDisplayResults = [{"CIS.NO": "Error", "Subject": `Result for ${versionKey} is malformed or an error.`, "Description": String(versionData), "Status": "ERROR", "Remediation": ""}];
    } else {
      newDisplayResults = [];
    }
    let Passed = 0;
    let Failed = 0;
    newDisplayResults.forEach((item) => {
      const status = getStatusForItem(item);
      if (status === "pass") Passed++;
      else if (status === "fail") Failed++;
    });
    setSelectedVersionKey(versionKey);
    setDisplayAuditResults(newDisplayResults);
    setSummary({ Passed, Failed });
    setExpandedRows([]);
    setSortDirection("none");
    setEditingIndex(null);
  }, [scanDetails, getStatusForItem]);

  const toggleSortDirection = useCallback(() => {
    const statuses = Array.from(new Set(displayAuditResults.map(item => getStatusForItem(item)))).sort();
    if (statuses.length === 0) {
      setSortDirection("none");
      return;
    }
    const cycleList = ["none", ...statuses];
    const currentIndex = cycleList.findIndex((status) => status === sortDirection);
    const nextIndex = (currentIndex + 1) % cycleList.length;
    setSortDirection(cycleList[nextIndex]);
  }, [displayAuditResults, getStatusForItem, sortDirection]);

  const sortedResults = useMemo(() => {
    if (!displayAuditResults) return [];
    const data = [...displayAuditResults];
    if (sortDirection !== "none") {
      return data.sort((a, b) => {
        const aStatus = getStatusForItem(a).toLowerCase().trim();
        const bStatus = getStatusForItem(b).toLowerCase().trim();
        if (aStatus === sortDirection && bStatus !== sortDirection) return -1;
        if (aStatus !== sortDirection && bStatus === sortDirection) return 1;
        return 0;
      });
    }
    return data;
  }, [displayAuditResults, sortDirection, getStatusForItem]);
  
  const handleConfirmDownload = useCallback(async () => {
    if (!projectName) {
      alert("Project name is missing!");
      return;
    }
    try {
      const response = await api.get(`/download/project/${projectName}/`, { responseType: "blob" });
      const blob = new Blob([response.data], { type: "application/zip" });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${projectName}_scans.zip`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error("Failed to download project excels:", error);
      alert("Failed to download the file.");
    } finally {
        setShowDownloadModal(false);
    }
  }, [projectName]);

  const handleAgentRescan = useCallback(async () => {
    if (!scanDetails?.scan_id || !fileToUpload) return;
    setIsRescanning(true);
    setUploadMessage("Uploading file...");
    setError("");
    const formData = new FormData();
    formData.append("file", fileToUpload);
    try {
      await api.post(`/scans/upload/${scanDetails.scan_id}/`, formData, { headers: { "Content-Type": "multipart/form-data" } });
      setUploadMessage("Scan result uploaded successfully ✅");
      alert("Scan result uploaded successfully!");
      await fetchScanData();
    } catch (err: any) {
      const errorMsg = err.response?.data?.error || `Server Error: ${err.response?.status}` || "Network error.";
      setUploadMessage(`Upload failed: ${errorMsg}`);
      setError(errorMsg);
    } finally {
      setIsRescanning(false);
      setShowRescanModal(false);
      setFileToUpload(null);
      setTimeout(() => setUploadMessage(null), 5000);
    }
  }, [scanDetails, fetchScanData, fileToUpload]);

  const handleRemoteRescan = useCallback(async () => {
    if (!scanDetails) return;
    setIsRescanning(true);
    setError("");
    try {
      const payload = { project_name: scanDetails.project_name, scan_name: scanDetails.scan_name, scan_author: scanDetails.scan_author, scan_type: scanDetails.scan_type, scan_data: scanDetails.scan_data };
      const response = await api.post('/scans/create-scan/', payload);
      const newVersion = response.data.scan?.scan_result_version;
      alert(newVersion ? `Rescan initiated! New version created: v${newVersion}` : "Rescan initiated successfully.");
      await fetchScanData();
    } catch (err: any) {
      const errorMsg = err.response?.data?.error?.detail || err.response?.data?.error || `Server Error: ${err.response?.status}` || "Network error.";
      setError(`Rescan failed: ${errorMsg}`);
    } finally {
      setIsRescanning(false);
      setShowRescanModal(false);
    }
  }, [scanDetails, fetchScanData]);

  const handleEditClick = (index: number, currentStatus: string) => {
    setEditingIndex(index);
    setEditingValue(currentStatus.toUpperCase());
  };

  const handleCancelEdit = () => {
    setEditingIndex(null);
    setEditingValue("");
  };

  const handleSaveEdit = async () => {
    if (editingIndex === null) return;
    const item = sortedResults[editingIndex];
    const newStatus = editingValue.trim().toUpperCase();
    if (!newStatus) return alert("Status cannot be empty.");
    const isNew = 'name' in item && 'results' in item;
    const id = isNew && item.name ? item.name : item["CIS.NO"];
    if (!id) return alert("Cannot update item without a valid identifier.");
    try {
        await api.put(`/scans/${scanDetails?.scan_id}/audit/${id}/`, { status: newStatus });
        const updatedDetails = { ...scanDetails! };
        const versionKey = selectedVersionKey!;
        const results = [...(updatedDetails.parsed_result_versions_data[versionKey] || []) as AuditResultItem[]];
        const itemIndex = results.findIndex((i: any) => (isNew ? i.name : i["CIS.NO"]) === id);
        if (itemIndex !== -1) {
            results[itemIndex] = { ...results[itemIndex], Status: newStatus };
            updatedDetails.parsed_result_versions_data = { ...updatedDetails.parsed_result_versions_data, [versionKey]: results };
            setScanDetails(updatedDetails);
            setDisplayAuditResults(results);
            let passed = 0, failed = 0;
            results.forEach(entry => {
                const status = getStatusForItem(entry);
                if (status === "pass") passed++;
                else if (status === "fail") failed++;
            });
            setSummary({ Passed: passed, Failed: failed });
        }
    } catch (error) {
        alert("Error updating status.");
    } finally {
        handleCancelEdit();
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') handleSaveEdit();
    else if (e.key === 'Escape') handleCancelEdit();
  };

  const formatDateWithSuffix = useCallback((date: Date) => {
    const day = date.getDate();
    const month = date.toLocaleString("en-GB", { month: "long" });
    const suffix = day % 10 === 1 && day !== 11 ? "st" : day % 10 === 2 && day !== 12 ? "nd" : day % 10 === 3 && day !== 13 ? "rd" : "th";
    return `${day}${suffix} ${month}`;
  }, []);

  const handleDragOver = (e: DragEvent<HTMLDivElement>) => { e.preventDefault(); setIsDragging(true); };
  const handleDragLeave = (e: DragEvent<HTMLDivElement>) => { e.preventDefault(); setIsDragging(false); };
  const handleDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      setFileToUpload(e.dataTransfer.files[0]);
    }
  };
  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFileToUpload(e.target.files[0]);
    }
  };

  return (
    <>
      <div className="flex h-screen text-black pt-24">
        <Sidebar settings={false} scanSettings={false} homeSettings={true} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title={`${scanName}`} />

          {loading ? <p className="text-center mt-8">Loading...</p> : error ? <p className="text-red-600 mt-4">{error}</p> : (
            <>
              <div className="flex gap-6 mt-8 items-start">
                <div className="w-[45%]">
                  <Card className="p-6 space-y-4 shadow-2xl border border-blue-300 border-l-4 rounded-none min-h-[280px]">
                    <h3 className="text-lg font-bold text-blue-400">Scan Information</h3>
                    <div className="text-sm grid grid-cols-[130px_1fr] gap-y-2">
                      <div className="font-semibold">Scan Name</div><div>{scanDetails?.scan_name}</div>
                      <div className="font-semibold">Author</div><div>{scanDetails?.scan_author}</div>
                      <div className="font-semibold">Type</div><div>{scanDetails?.scan_type}</div>
                      <div className="font-semibold">Status</div><div className={`font-medium ${scanDetails?.scan_status === "Pending" ? "text-yellow-500" : "text-green-600"}`}>{scanDetails?.scan_status}</div>
                      <div className="font-semibold">Created At</div><div>{scanDetails?.scan_time ? <>{formatDateWithSuffix(new Date(scanDetails.scan_time))}, {new Date(scanDetails.scan_time).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false })}</> : "N/A"}</div>
                      <div className="font-semibold">Result Version</div><div>{selectedVersionKey ? selectedVersionKey.substring(1) : (scanDetails?.scan_result_version || 0)}</div>
                    </div>
                  </Card>
                </div>
                <div className="w-[55%]">
                  <Card className="p-6 shadow-2xl border border-blue-300 border-l-4 rounded-none min-h-[282px] flex items-center justify-center">
                    <ScanPieChart data={summary} />
                  </Card>
                </div>
              </div>
              <div className="border-t-2 border-gray-300 my-8" />
              {uploadMessage && <div className={`mt-4 px-4 py-2 rounded text-sm ${uploadMessage.includes("success") ? "bg-green-100 text-green-700 border border-green-400" : "bg-red-100 text-red-700 border border-red-400"}`}>{uploadMessage}</div>}
              <div className="flex justify-start mb-2 gap-2">
                <Button onClick={() => setShowDownloadModal(true)} className="flex items-center justify-center w-32 px-4 py-2 bg-black text-white cursor-pointer hover:bg-gray-800 transition rounded-none"><Download size={16} className="mr-2"/> Download</Button>
                <Button onClick={() => setShowRescanModal(true)} disabled={isRescanning} className="flex items-center justify-center w-32 px-4 py-2 bg-black text-white cursor-pointer hover:bg-gray-800 transition rounded-none disabled:opacity-50 disabled:cursor-not-allowed"><RefreshCw size={16} className="mr-2"/> {isRescanning ? "Rescanning..." : "Rescan"}</Button>
                {scanDetails?.available_result_versions && scanDetails.available_result_versions.length > 0 && (
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild><Button variant="outline" className="px-4 py-2 bg-gray-100 text-black hover:bg-gray-200 transition rounded-none"><span>Version: {selectedVersionKey ? selectedVersionKey.substring(1) : 'Latest'}</span></Button></DropdownMenuTrigger>
                    <DropdownMenuContent align="start" className="w-40">
                      {scanDetails.available_result_versions.map((versionKey) => <DropdownMenuItem key={versionKey} onClick={() => handleVersionChange(versionKey)} className={selectedVersionKey === versionKey ? "bg-blue-100 text-blue-700 font-semibold" : ""}>Version {versionKey.substring(1)} {versionKey === `v${scanDetails.scan_result_version}` && "(Latest)"}</DropdownMenuItem>)}
                    </DropdownMenuContent>
                  </DropdownMenu>
                )}
              </div>
              <Card className="w-full mt-2 shadow-lg border border-gray-200 bg-white rounded-none">
                <div className="p-5">
                  <div className="flex justify-between items-center mb-2"><h2 className="text-xl font-semibold text-gray-800">Audit Results {selectedVersionKey && `(Version ${selectedVersionKey.substring(1)})`}</h2></div>
                  <div className="h-[450px] overflow-y-auto">
                    <table className="table-auto w-full text-sm">
                      <thead className="sticky top-0 z-10 bg-gray-100"><tr className="text-gray-700 border-b border-gray-400"><th className="text-left px-4 py-2 w-[20%]">Audit ID</th><th className="text-left px-4 py-2 w-[55%]">Audit Name</th><th className="text-left px-4 py-2 w-[15%] cursor-pointer hover:underline" onClick={toggleSortDirection}><div className="flex items-center gap-1">Status {sortDirection !== "none" && (<span className="text-xs bg-gray-200 px-1 py-0.5 rounded">{sortDirection.toUpperCase()}</span>)}</div></th><th className="px-4 py-2 w-[10%]"></th></tr></thead>
                      <tbody>
                        {sortedResults.length === 0 ? <tr><td colSpan={4} className="text-center py-4">No audit data available.</td></tr> : sortedResults.map((item, index) => {
                          const isExpanded = expandedRows.includes(index);
                          const isNew = 'name' in item && 'results' in item;
                          const status = getStatusForItem(item);
                          const isEditing = editingIndex === index;
                          return (
                            <React.Fragment key={index}>
                              <tr onClick={() => !isEditing && setExpandedRows(p => p.includes(index) ? p.filter(i => i !== index) : [...p, index])} className={`border-b transition duration-200 ${index % 2 === 0 ? "bg-white" : "bg-gray-50"} ${!isEditing && "hover:bg-blue-50 cursor-pointer"}`}>
                                <td className="px-4 py-3 font-medium">{item["CIS.NO"] || (isNew && item.name ? item.name.split('_')[0]?.replace(/_/g, '.') : 'N/A')}</td>
                                <td className="px-4 py-3">{item.Subject || (isNew && item.name ? item.name.replace(/_/g, ' ').replace(/\bScored\b/g, '').trim() : 'N/A')}</td>
                                <td className="px-4 py-3 uppercase tracking-wide">
                                  {isEditing ? <div className="flex items-center gap-2"><Input type="text" value={editingValue} onChange={e => setEditingValue(e.target.value)} onKeyDown={handleKeyDown} className="h-8" autoFocus /><Button variant="ghost" size="icon" className="h-8 w-8 text-green-600 hover:bg-green-100" onClick={handleSaveEdit}><Check size={18} /></Button><Button variant="ghost" size="icon" className="h-8 w-8 text-red-600 hover:bg-red-100" onClick={handleCancelEdit}><X size={18} /></Button></div> : <>{status === "pass" ? <CircleCheck size={16} className="text-green-600 inline-block mr-1" /> : status === "fail" ? <CircleX size={16} className="text-red-600 inline-block mr-1" /> : <span className="inline-block w-2 h-2 mr-1 bg-gray-400 rounded-full" />} {status.toUpperCase()}</>}
                                </td>
                                <td className="px-4 py-3 text-right"><DropdownMenu><DropdownMenuTrigger asChild><Button variant="ghost" className="h-8 w-8 p-0"><span className="sr-only">Open menu</span><MoreVertical className="h-4 w-4 text-gray-600" /></Button></DropdownMenuTrigger><DropdownMenuContent align="end"><DropdownMenuItem onClick={() => handleEditClick(index, status)} disabled={isEditing}>Edit</DropdownMenuItem><DropdownMenuItem className="text-red-600">Delete</DropdownMenuItem></DropdownMenuContent></DropdownMenu></td>
                              </tr>
                              {isExpanded && !isEditing && <tr className="bg-gray-100 border-b"><td colSpan={4} className="px-6 py-4 text-sm text-gray-700"><div className="grid grid-cols-[120px_1fr] gap-y-2 gap-x-4"><div className="font-semibold">Description:</div><div>{item.Description ? item.Description : isNew && item.results != null ? typeof item.results === 'string' ? item.results : Array.isArray(item.results) ? <pre className="whitespace-pre-wrap text-xs bg-gray-50 p-2 rounded-md">{JSON.stringify(item.results, null, 2)}</pre> : "N/A" : "No results provided."}</div><div className="font-semibold">Remediation:</div><div>{item.Remediation ? item.Remediation : isNew ? "N/A (Remediation not available in this format)" : "N/A"}</div></div></td></tr>}
                            </React.Fragment>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              </Card>
            </>
          )}
        </div>
      </div>

      {showDownloadModal && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 transition-opacity">
          <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md m-4">
            <div className="flex items-start">
              <div className="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10"><Download className="h-6 w-6 text-blue-600" /></div>
              <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3 className="text-lg font-medium text-gray-900">Confirm Download</h3>
                <div className="mt-2"><p className="text-sm text-gray-500">Download all results for <strong>{projectName}</strong>?</p></div>
              </div>
            </div>
            <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse gap-3">
              <Button onClick={handleConfirmDownload} className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700">Confirm</Button>
              <Button variant="outline" onClick={() => setShowDownloadModal(false)} className="w-full sm:w-auto mt-2 sm:mt-0">Cancel</Button>
            </div>
          </div>
        </div>
      )}

      {showRescanModal && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 transition-opacity">
          <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md m-4">
            {scanDetails?.scan_data?.auditMethod === 'agent' ? <>
              <h3 className="text-lg font-medium text-gray-900 mb-4">Upload New Agent Result</h3>
              <div className={`relative border-2 border-dashed rounded-lg p-6 text-center hover:border-gray-400 transition-colors ${isDragging ? 'border-blue-500 bg-blue-50' : 'border-gray-300'}`} onDragOver={handleDragOver} onDragLeave={handleDragLeave} onDrop={handleDrop} onClick={() => fileInputRef.current?.click()}>
                <UploadCloud className="mx-auto h-12 w-12 text-gray-400" />
                <p className="mt-2 text-sm text-gray-600"><span className="font-semibold text-blue-600">Click to upload</span> or drag & drop</p>
                <p className="text-xs text-gray-500">JSON or CSV files</p>
                <input type="file" ref={fileInputRef} onChange={handleFileSelect} accept=".csv,.json" className="hidden" />
              </div>
              {fileToUpload && <div className="mt-4 flex items-center justify-between bg-gray-50 p-2 rounded-md border"><div className="flex items-center gap-2"><FileIcon className="h-5 w-5 text-gray-500" /><span className="text-sm font-medium text-gray-700">{fileToUpload.name}</span></div><button onClick={() => setFileToUpload(null)} className="text-red-500 hover:text-red-700"><X size={16}/></button></div>}
              <div className="mt-6 flex justify-end gap-3"><Button variant="outline" onClick={() => setShowRescanModal(false)}>Cancel</Button><Button onClick={handleAgentRescan} disabled={!fileToUpload || isRescanning} className="bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300">{isRescanning ? 'Uploading...' : 'Upload & Rescan'}</Button></div>
            </> : <>
              <div className="flex items-start">
                <div className="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-yellow-100 sm:mx-0 sm:h-10 sm:w-10"><AlertTriangle className="h-6 w-6 text-yellow-600" /></div>
                <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <h3 className="text-lg font-medium text-gray-900">Confirm Rescan</h3>
                  <p className="mt-2 text-sm text-gray-500">Start a new scan? This will create a new result version.</p>
                </div>
              </div>
              <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse gap-3"><Button onClick={handleRemoteRescan} disabled={isRescanning} className="w-full sm:w-auto bg-yellow-600 hover:bg-yellow-700 text-white">{isRescanning ? 'Initiating...' : 'Confirm'}</Button><Button variant="outline" onClick={() => setShowRescanModal(false)} className="w-full sm:w-auto mt-2 sm:mt-0">Cancel</Button></div>
            </>}
          </div>
        </div>
      )}
    </>
  );
};

export default ScanResult;

