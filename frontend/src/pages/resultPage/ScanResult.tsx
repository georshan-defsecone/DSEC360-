import { useParams } from "react-router-dom";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import api from "../api";
import { useEffect, useState, useCallback } from "react";
import { CircleCheck, CircleX, MoreVertical, ChevronDown } from "lucide-react"; 
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

// Define interfaces for better type safety
interface AuditResultItem {
  "CIS.NO"?: string;
  Subject?: string;
  Description?: string;
  "Current Settings"?: string | null;
  Status?: string; 
  Remediation?: string;
  name?: string; 
  results?: any; 
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

  const [summary, setSummary] = useState<ScanSummary>({
    Passed: 0,
    Failed: 0,
  });

  const [scanDetails, setScanDetails] = useState<ScanDetailsBackend | null>(null);
  const [displayAuditResults, setDisplayAuditResults] = useState<AuditResultItem[]>([]);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>("");
  const [expandedRows, setExpandedRows] = useState<number[]>([]);
  const [sortDirection, setSortDirection] = useState<SortDirection>("none");
  const [isRescanning, setIsRescanning] = useState(false);
  const [selectedVersionKey, setSelectedVersionKey] = useState<string | null>(null); 

  // --- Helper to deduce status from AuditResultItem ---
  const getStatusForItem = useCallback((item: AuditResultItem): string => {
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


  // --- fetchScanData function: Initial load and re-load after rescan ---
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


  // --- handleVersionChange to select and display a different version ---
  const handleVersionChange = useCallback((versionKey: string) => {
    if (!scanDetails || !scanDetails.parsed_result_versions_data) return; 

    const versionData = scanDetails.parsed_result_versions_data[versionKey];
    let newDisplayResults: AuditResultItem[] = [];

    if (Array.isArray(versionData)) {
      newDisplayResults = versionData;
    } else if (versionData !== undefined && versionData !== null) {
      console.warn(`Selected version ${versionKey} is not an array:`, versionData);
      newDisplayResults = [{ 
        "CIS.NO": "Error",
        "Subject": `Result for ${versionKey} is malformed or an error.`, 
        "Description": String(versionData), 
        "Status": "ERROR",
        "Remediation": ""
      }];
    } else {
      console.warn(`No data found for selected version ${versionKey}.`);
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
  }, [scanDetails, getStatusForItem]);


  const getAllStatuses = useCallback((): string[] => {
    const statusSet = new Set<string>();
    displayAuditResults.forEach((item: AuditResultItem) => {
      statusSet.add(getStatusForItem(item));
    });
    return Array.from(statusSet).sort();
  }, [displayAuditResults, getStatusForItem]);


  const toggleSortDirection = useCallback(() => {
    const statuses = getAllStatuses();
    if (statuses.length === 0) {
        setSortDirection("none");
        return;
    }

    const cycleList = ["none", ...statuses];
    const currentIndex = cycleList.findIndex((status) => status === sortDirection);
    const nextIndex = (currentIndex + 1) % cycleList.length;
    setSortDirection(cycleList[nextIndex]);
  }, [getAllStatuses, sortDirection]);


  const getSortedResults = useCallback(() => {
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

  const sortedResults = getSortedResults();


  const handleDownloadProjectExcels = useCallback(async () => {
    if (!projectName) {
      alert("Project name is missing!");
      return;
    }

    try {
      const response = await api.get(`/download/project/${projectName}/`, {
        responseType: "blob",
      });

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
    }
  }, [projectName]);


  const handleRescan = useCallback(async () => {
    if (!scanDetails) {
        alert("Scan details not loaded, cannot rescan.");
        return;
    }

    setIsRescanning(true);
    setError("");

    try {
        const rescanPayload = {
            project_name: scanDetails.project_name,
            scan_name: scanDetails.scan_name,
            scan_author: scanDetails.scan_author,
            scan_type: scanDetails.scan_type,
            scan_data: scanDetails.scan_data, 
        };

        const response = await api.post('/scans/create-scan/', rescanPayload);

        const newVersion = response.data.scan?.scan_result_version;
        if (newVersion) {
            console.log("Rescan initiated successfully:", response.data);
            alert(`Rescan initiated! New version created: v${newVersion}`);
        } else {
            console.warn("Rescan initiated, but new version not found in response:", response.data);
            alert("Rescan initiated successfully, but could not determine new version.");
        }
        
        await fetchScanData(); 

    } catch (err: any) {
        console.error("Failed to initiate rescan:", err);
        if (err.response) {
            if (err.response.data && typeof err.response.data.error === 'string') {
                setError(err.response.data.error);
            } else if (err.response.data && err.response.data.error && typeof err.response.data.error.detail === 'string') {
                setError(err.response.data.error.detail); 
            }
            else {
                setError(`Rescan failed: Server Error ${err.response.status} - ${err.response.statusText}`);
            }
        } else {
            setError("Rescan failed. Network error or unexpected response structure.");
        }
        setIsRescanning(false);
    }
  }, [scanDetails, fetchScanData]);


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
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header title={`${scanName}`} />

        {loading ? (
          <p>Loading...</p>
        ) : error ? (
          <p className="text-red-600 mt-4">{error}</p>
        ) : (
          <>
            {/* Scan Info + Pie Chart */}
            <div className="flex gap-6 mt-8 items-start">
              <div className="w-[45%]">
                <Card className="p-6 space-y-4 shadow-2xl border border-blue-300 border-l-4 rounded-none min-h-[280px]">
                  <h3 className="text-lg font-bold text-blue-400">
                    Scan Information
                  </h3>
                  <div className="text-sm grid grid-cols-[130px_1fr] gap-y-2">
                    <div className="font-semibold">Scan Name</div>
                    <div>{scanDetails?.scan_name}</div> 

                    <div className="font-semibold">Author</div>
                    <div>{scanDetails?.scan_author}</div>

                    <div className="font-semibold">Type</div>
                    <div>{scanDetails?.scan_type}</div>

                    <div className="font-semibold">Status</div>
                    <div
                      className={`font-medium ${
                        scanDetails?.scan_status === "Pending"
                          ? "text-yellow-500"
                          : "text-green-600"
                      }`}
                    >
                      {scanDetails?.scan_status}
                    </div>

                    <div className="font-semibold">Created At</div>
                    <div>
                      {scanDetails?.scan_time ? (
                        <>
                          {formatDateWithSuffix(
                            new Date(scanDetails.scan_time)
                          )}
                          ,{" "}
                          {new Date(scanDetails.scan_time).toLocaleTimeString(
                            "en-GB",
                            {
                              hour: "2-digit",
                              minute: "2-digit",
                              hour12: false,
                            }
                          )}
                        </>
                      ) : (
                        "N/A"
                      )}
                    </div>
                    <div className="font-semibold">Result Version</div>
                    {/* Display the number part of the selectedVersion (e.g., '1' from 'v1') */}
                    <div>{selectedVersionKey ? selectedVersionKey.substring(1) : (scanDetails?.scan_result_version || 0)}</div> 
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

            <div className="flex justify-start mb-2 gap-2">
              <button
                onClick={handleDownloadProjectExcels}
                className="flex items-center justify-center w-28 px-4 py-2 bg-black text-white  cursor-pointer hover:bg-gray-800 transition rounded-none"
              >
                Download
              </button>
              <Button 
                onClick={handleRescan}
                disabled={isRescanning}
                className="flex items-center justify-center w-28 px-4 py-2 bg-black text-white cursor-pointer hover:bg-gray-800 transition rounded-none disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isRescanning ? "Rescanning..." : "Rescan"}
              </Button>

              {/* Version Selector Dropdown */}
              {scanDetails?.available_result_versions && scanDetails.available_result_versions.length > 0 && ( 
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    {/* The Button is correctly wrapped by DropdownMenuTrigger with asChild */}
                    <Button 
                      variant="outline" 
                      className="flex items-center justify-center px-4 py-2 bg-gray-100 text-black hover:bg-gray-200 transition rounded-none"
                    >
                      View Version: {selectedVersionKey ? selectedVersionKey.substring(1) : 'Latest'} <ChevronDown className="ml-2 h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="start" className="w-40">
                    {scanDetails.available_result_versions.map((versionKey) => (
                      <DropdownMenuItem 
                        key={versionKey} 
                        onClick={() => handleVersionChange(versionKey)}
                        className={selectedVersionKey === versionKey ? "bg-blue-100 text-blue-700 font-semibold" : ""}
                      >
                        Version {versionKey.substring(1)} {versionKey === `v${scanDetails.scan_result_version}` && "(Latest)"}
                      </DropdownMenuItem>
                    ))}
                  </DropdownMenuContent>
                </DropdownMenu>
              )}
            </div>

            {/* Audit Table */}
            <Card className="w-full mt-2 shadow-lg border border-gray-200 bg-white rounded-none">
              <div className="p-5">
                <div className="flex justify-between items-center mb-2">
                  <h2 className="text-xl font-semibold text-gray-800">
                    Audit Results {selectedVersionKey && `(Version ${selectedVersionKey.substring(1)})`}
                  </h2>
                </div>

                <div className="h-[450px] overflow-y-auto">
                  <table className="table-auto w-full text-sm">
                    <thead className="sticky top-0 z-10 bg-gray-100">
                      <tr className="text-gray-700 border-b border-gray-400">
                        <th className="text-left px-4 py-2 w-[20%]">
                          Audit ID
                        </th>
                        <th className="text-left px-4 py-2 w-[55%]">
                          Audit Name
                        </th>
                        <th
                          className="text-left px-4 py-2 w-[15%] cursor-pointer hover:underline"
                          onClick={toggleSortDirection}
                        >
                          <div className="flex items-center gap-1">
                            Status
                            {sortDirection !== "none" && (
                              <span className="text-xs bg-gray-200 px-1 py-0.5 rounded">
                                {sortDirection.toUpperCase()}
                              </span>
                            )}
                          </div>
                        </th>
                        <th className="px-4 py-2 w-[10%]"></th>
                      </tr>
                    </thead>
                    <tbody>
                      {sortedResults.length === 0 ? (
                        <tr>
                          <td colSpan={4} className="text-center py-4">
                            No audit data available for this version.
                          </td>
                        </tr>
                      ) : (
                        sortedResults.map((item: AuditResultItem, index: number) => {
                          const isExpanded = expandedRows.includes(index);
                          const isNewJsonFormatFlag = 'name' in item && 'results' in item;
                          const currentStatus = getStatusForItem(item);

                          return (
                            <React.Fragment key={index}>
                              <tr
                                onClick={() =>
                                  setExpandedRows((prev) =>
                                    prev.includes(index)
                                      ? prev.filter((i) => i !== index)
                                      : [...prev, index]
                                  )
                                }
                                className={`border-b cursor-pointer transition duration-200 ${
                                  index % 2 === 0 ? "bg-white" : "bg-gray-50"
                                } hover:bg-blue-50`}
                              >
                                <td className="px-4 py-3 font-medium">
                                  {item["CIS.NO"] || (isNewJsonFormatFlag && item.name ? item.name.split('_')[0]?.replace(/_/g, '.') : 'N/A')}
                                </td>
                                <td className="px-4 py-3">
                                  {item.Subject || (isNewJsonFormatFlag && item.name ? item.name.replace(/_/g, ' ').replace(/\bScored\b/g, '').trim() : 'N/A')}
                                </td>
                                <td className="px-4 py-3 uppercase tracking-wide">
                                  {currentStatus === "pass" ? (
                                    <CircleCheck
                                      size={16}
                                      className="text-green-600 inline-block mr-1"
                                    />
                                  ) : currentStatus === "fail" ? (
                                    <CircleX
                                      size={16}
                                      className="text-red-600 inline-block mr-1"
                                    />
                                  ) : (
                                    <span className="inline-block w-2 h-2 mr-1 bg-gray-400 rounded-full" />
                                  )}
                                  {currentStatus.toUpperCase()}
                                </td>
                                <td className="px-4 py-3 text-right">
                                  <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                      <Button variant="ghost" className="h-8 w-8 p-0">
                                        <span className="sr-only">Open menu</span>
                                        <MoreVertical className="h-4 w-4 text-gray-600" />
                                      </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                      <DropdownMenuItem
                                        onClick={async () => {
                                          const rawInput = prompt(
                                            "Enter new status (anything is allowed):"
                                          );
                                          if (!rawInput) return;
                                          const newStatus = rawInput.trim().toUpperCase();

                                          try {
                                            const auditItemIdentifier = isNewJsonFormatFlag && item.name ? item.name : item["CIS.NO"];
                                            await api.put(
                                              `/scans/${scanDetails?.scan_id}/audit/${auditItemIdentifier}/`,
                                              { status: newStatus }
                                            );

                                            const updatedScanDetails = { ...scanDetails! };
                                            const targetVersionKey = selectedVersionKey!; 
                                            
                                            const currentVersionResults = [...(updatedScanDetails.parsed_result_versions_data[targetVersionKey] || []) as AuditResultItem[]];
                                            
                                            const itemIndex = currentVersionResults.findIndex(
                                                (i: any) => (isNewJsonFormatFlag ? i.name : i["CIS.NO"]) === auditItemIdentifier
                                            );
                                            
                                            if (itemIndex !== -1) {
                                                currentVersionResults[itemIndex] = { ...currentVersionResults[itemIndex], Status: newStatus };
                                                
                                                updatedScanDetails.parsed_result_versions_data = {
                                                    ...updatedScanDetails.parsed_result_versions_data,
                                                    [targetVersionKey]: currentVersionResults
                                                };
                                                
                                                setScanDetails(updatedScanDetails);
                                                setDisplayAuditResults(currentVersionResults);

                                                let updatedPassed = 0;
                                                let updatedFailed = 0;
                                                currentVersionResults.forEach((entry) => {
                                                    const statusForSummary = getStatusForItem(entry);
                                                    if (statusForSummary === "pass") updatedPassed++;
                                                    else if (statusForSummary === "fail") updatedFailed++;
                                                });
                                                setSummary({ Passed: updatedPassed, Failed: updatedFailed });
                                            }

                                          } catch (error) {
                                            console.error("Failed to update status:", error);
                                            alert("Error updating status.");
                                          }
                                        }}
                                      >
                                        Edit
                                      </DropdownMenuItem>

                                      <DropdownMenuItem className="text-red-600">
                                        Delete
                                      </DropdownMenuItem>
                                    </DropdownMenuContent>
                                  </DropdownMenu>
                                </td>
                              </tr>

                              {isExpanded && (
                                <tr className="bg-gray-100 border-b">
                                  <td
                                    colSpan={4}
                                    className="px-6 py-4 text-sm text-gray-700"
                                  >
                                    <div className="grid grid-cols-[120px_1fr] gap-y-2 gap-x-4">
                                      <div className="font-semibold">
                                        Description:
                                      </div>
                                      <div>
                                        {item.Description ? item.Description : 
                                          (isNewJsonFormatFlag && item.results !== undefined && item.results !== null) ? (
                                            typeof item.results === 'string' ? (
                                              item.results
                                            ) : Array.isArray(item.results) ? (
                                              <pre className="whitespace-pre-wrap text-xs bg-gray-50 p-2 rounded-md">
                                                {JSON.stringify(item.results, null, 2)}
                                              </pre>
                                            ) : (
                                              "N/A"
                                            )
                                          ) : "No detailed results provided."}
                                      </div>

                                      <div className="font-semibold">
                                        Remediation:</div>
                                      <div>
                                        {item.Remediation ? item.Remediation : 
                                          (isNewJsonFormatFlag ? (
                                              "N/A (Remediation field not directly available in this new JSON structure)"
                                            ) : "N/A")}
                                      </div>
                                    </div>
                                  </td>
                                </tr>
                              )}
                            </React.Fragment>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </Card>
          </>
        )}
      </div>
    </div>
  );
};

export default ScanResult;