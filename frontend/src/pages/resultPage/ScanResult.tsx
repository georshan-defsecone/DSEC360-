import { useParams } from "react-router-dom";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import api from "../api";
import { useEffect, useState } from "react";
import { CircleCheck, CircleX, MoreVertical } from "lucide-react";
import { Card } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from "@/components/ui/dropdown-menu";
import React from "react";
import ScanPieChart from "@/components/ScanPieChart";

type SortDirection = "none" | string;

const ScanResult = () => {
  const { projectName, scanName } = useParams<{
    projectName: string;
    scanName: string;
  }>();

  const [summary, setSummary] = useState<{ Passed: number; Failed: number }>({
    Passed: 0,
    Failed: 0,
  });

  const [scanDetails, setScanDetails] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [expandedRows, setExpandedRows] = useState<number[]>([]);
  const [sortDirection, setSortDirection] = useState<SortDirection>("none");

  useEffect(() => {
    if (!projectName || !scanName) {
      setError("Missing scan information.");
      setLoading(false);
      return;
    }

    (async () => {
      try {
        const response = await api.get(
          `/scans/scan-result/${projectName}/${scanName}`,
          { responseType: "blob" }
        );

        const jsonText = await response.data.text();
        const parsed = JSON.parse(jsonText);

        const parsedScan = parsed || {};
        const output = parsedScan?.parsed_scan_result || [];

        const scanMeta = {
          id: parsedScan?.scan_id,
          name: parsedScan?.scan_name,
          author: parsedScan?.scan_author,
          status: parsedScan?.scan_status,
          type: parsedScan?.scan_type,
          project: parsedScan?.project,
          data: parsedScan?.scan_data || {},
          createdAt: parsedScan?.scan_time,
        };

        let Passed = 0;
        let Failed = 0;

        output.forEach((item: any) => {
          const status = item.Status?.toLowerCase().trim();
          if (status === "pass") Passed++;
          else if (status === "fail") Failed++;
        });

        setScanDetails({ ...scanMeta, parsed_scan_result: output });
        setSummary({ Passed, Failed });
      } catch (err) {
        console.error(err);
        setError("Failed to fetch or parse scan result.");
      } finally {
        setLoading(false);
      }
    })();
  }, [projectName, scanName]);

  const getAllStatuses = (): string[] => {
    const statusSet = new Set<string>();
    scanDetails?.parsed_scan_result?.forEach((item: any) => {
      const status = item.Status?.toLowerCase().trim();
      if (status) statusSet.add(status);
    });
    return Array.from(statusSet);
  };

  const toggleSortDirection = () => {
    const statuses = getAllStatuses();
    if (statuses.length === 0) return;

    const cycleList = ["none", ...statuses];
    const currentIndex = cycleList.findIndex(
      (status) => status === sortDirection
    );
    const nextIndex = (currentIndex + 1) % cycleList.length;
    setSortDirection(cycleList[nextIndex]);
  };

  const getSortedResults = () => {
    if (!scanDetails?.parsed_scan_result) return [];

    const data = [...scanDetails.parsed_scan_result];
    if (sortDirection !== "none") {
      return data.sort((a, b) => {
        const aStatus = a.Status?.toLowerCase().trim();
        const bStatus = b.Status?.toLowerCase().trim();

        if (aStatus === sortDirection && bStatus !== sortDirection) return -1;
        if (aStatus !== sortDirection && bStatus === sortDirection) return 1;
        return 0;
      });
    }

    return data;
  };

  const sortedResults = getSortedResults();

  const handleDownloadProjectExcels = async () => {
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
  };

  const formatDateWithSuffix = (date: Date) => {
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
  };

  return (
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header
          title={`Project: ${projectName ?? "Unknown"} / Scan: ${
            scanName ?? "Unnamed"
          }`}
        />

        {loading ? (
          <p>Loading...</p>
        ) : error ? (
          <p className="text-red-600 mt-4">{error}</p>
        ) : (
          <>
            <div className="flex gap-6 mt-8 items-start">
              <div className="w-1/3">
                <Card className="p-6 space-y-4 shadow-2xl border border-blue-300 border-l-4 mt-15 rounded-none">
                  <h3 className="text-lg font-bold text-blue-400">
                    Scan Information
                  </h3>
                  <div className="text-sm grid grid-cols-[130px_1fr] gap-y-2">
                    <div className="font-semibold">Scan Name</div>
                    <div>{scanDetails?.name}</div>

                    <div className="font-semibold">Author</div>
                    <div>{scanDetails?.author}</div>

                    <div className="font-semibold">Type</div>
                    <div>{scanDetails?.type}</div>

                    <div className="font-semibold">Status</div>
                    <div
                      className={`font-medium ${
                        scanDetails?.status === "Pending"
                          ? "text-yellow-500"
                          : "text-green-600"
                      }`}
                    >
                      {scanDetails?.status}
                    </div>

                    <div className="font-semibold">Created At</div>
                    <div>
                      {scanDetails?.createdAt ? (
                        <>
                          {formatDateWithSuffix(
                            new Date(scanDetails.createdAt)
                          )}
                          ,{" "}
                          {new Date(scanDetails.createdAt).toLocaleTimeString(
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
                  </div>
                </Card>
              </div>

              <div className="w-2/3">
                <Card className="p-6 shadow-2xl border border-blue-300 border-l-4 rounded-none">
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
              <button className="flex items-center justify-center w-28 px-4 py-2 bg-black text-white cursor-pointer hover:bg-gray-800 transition rounded-none">
                Rescan
              </button>
            </div>

            <Card className="w-full mt-2 shadow-lg border border-gray-200 bg-white rounded-none">
              <div className="p-5">
                <div className="flex justify-between items-center mb-2">
                  <h2 className="text-xl font-semibold text-gray-800">
                    Audit Results
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
                            No audit data available.
                          </td>
                        </tr>
                      ) : (
                        sortedResults.map((item: any, index: number) => {
                          const isExpanded = expandedRows.includes(index);

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
                                  {item["CIS.NO"]}
                                </td>
                                <td className="px-4 py-3">{item["Subject"]}</td>
                                <td className="px-4 py-3 uppercase tracking-wide">
                                  {item.Status?.toLowerCase().trim() ===
                                  "pass" ? (
                                    <CircleCheck
                                      size={16}
                                      className="text-green-600 inline-block mr-1"
                                    />
                                  ) : item.Status?.toLowerCase().trim() ===
                                    "fail" ? (
                                    <CircleX
                                      size={16}
                                      className="text-red-600 inline-block mr-1"
                                    />
                                  ) : (
                                    <span className="inline-block w-2 h-2 mr-1 bg-gray-400 rounded-full" />
                                  )}
                                  {item.Status?.toUpperCase()}
                                </td>
                                <td className="px-4 py-3 text-right">
                                  <DropdownMenu>
                                    <DropdownMenuTrigger className="focus:outline-none hover:underline cursor-pointer">
                                      <MoreVertical className="h-5 w-5 text-gray-600" />
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                      <DropdownMenuItem
                                        onClick={async () => {
                                          const rawInput = prompt(
                                            "Enter new status (anything is allowed):"
                                          );

                                          if (!rawInput) return;

                                          const newStatus = rawInput
                                            .trim()
                                            .toUpperCase(); // Convert to ALL CAPS

                                          try {
                                            await api.put(
                                              `/scans/${scanDetails.id}/audit/${item["CIS.NO"]}/`,
                                              {
                                                status: newStatus,
                                              }
                                            );

                                            // Update local scan state
                                            const updatedScan = {
                                              ...scanDetails,
                                            };
                                            const indexToUpdate =
                                              updatedScan.parsed_scan_result.findIndex(
                                                (i: any) =>
                                                  i["CIS.NO"] === item["CIS.NO"]
                                              );

                                            if (indexToUpdate !== -1) {
                                              updatedScan.parsed_scan_result[
                                                indexToUpdate
                                              ].Status = newStatus;
                                              setScanDetails(updatedScan);
                                            }

                                            // Recalculate PASS / FAIL counts (optional, based on actual lowercase comparison)
                                            const updatedPassed =
                                              updatedScan.parsed_scan_result.filter(
                                                (entry: any) =>
                                                  entry.Status?.toLowerCase().trim() ===
                                                  "pass"
                                              ).length;

                                            const updatedFailed =
                                              updatedScan.parsed_scan_result.filter(
                                                (entry: any) =>
                                                  entry.Status?.toLowerCase().trim() ===
                                                  "fail"
                                              ).length;

                                            setSummary({
                                              Passed: updatedPassed,
                                              Failed: updatedFailed,
                                            });
                                          } catch (error) {
                                            console.error(
                                              "Failed to update status:",
                                              error
                                            );
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
                                        Audit Name:
                                      </div>
                                      <div>{item["Subject"]}</div>

                                      <div className="font-semibold">
                                        Description:
                                      </div>
                                      <div>{item["Description"]}</div>

                                      <div className="font-semibold">
                                        Remediation:
                                      </div>
                                      <div>{item["Remediation"]}</div>
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
