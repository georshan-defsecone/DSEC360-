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

  return (
    <div className="flex h-screen text-black pt-24">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
        <Header
          title={`Result: ${projectName ?? "Unknown"} - ${scanName ?? ""}`}
        />

        {loading ? (
          <p>Loading...</p>
        ) : error ? (
          <p className="text-red-600 mt-4">{error}</p>
        ) : (
          <>
            <div className="flex gap-6 mt-8 items-start">
              <div className="w-1/3">
                <Card className="p-6 space-y-4 shadow-2xl border border-blue-300 border-l-4 ml-5 rounded-none">
                  <h3 className="text-lg font-bold text-blue-400">
                    Scan Information
                  </h3>
                  <div className="text-sm grid grid-cols-[130px_1fr] gap-y-2">
                    <div className="font-semibold">Scan Name:</div>
                    <div>{scanDetails?.name}</div>

                    <div className="font-semibold">Author:</div>
                    <div>{scanDetails?.author}</div>

                    <div className="font-semibold">Type:</div>
                    <div>{scanDetails?.type}</div>

                    <div className="font-semibold">Status:</div>
                    <div
                      className={`font-medium ${
                        scanDetails?.status === "Pending"
                          ? "text-yellow-500"
                          : "text-green-600"
                      }`}
                    >
                      {scanDetails?.status}
                    </div>

                    <div className="font-semibold">Created At:</div>
                    <div>
                      {scanDetails?.createdAt
                        ? new Date(scanDetails.createdAt).toLocaleTimeString(
                            [],
                            {
                              hour: "2-digit",
                              minute: "2-digit",
                              hour12: true,
                            }
                          )
                        : "N/A"}
                    </div>

                    <div className="font-semibold">OS:</div>
                    <div>{scanDetails?.data?.os || "N/A"}</div>

                    <div className="font-semibold">Domain:</div>
                    <div>{scanDetails?.data?.domain || "N/A"}</div>
                  </div>
                </Card>
              </div>

              <div className="w-2/3 ml-25">
                <ScanPieChart data={summary} />
              </div>
            </div>

            <div className="border-t-2 border-gray-300 my-8" />

            <Card className="w-full mt-8 shadow-lg border border-gray-200 bg-white rounded-none">
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
                        <th className="text-left px-4 py-2 w-[15%]">Status</th>
                        <th className="px-4 py-2 w-[10%]"></th>
                      </tr>
                    </thead>
                    <tbody>
                      {scanDetails?.parsed_scan_result?.length === 0 ? (
                        <tr>
                          <td colSpan={4} className="text-center py-4">
                            No audit data available.
                          </td>
                        </tr>
                      ) : (
                        scanDetails?.parsed_scan_result?.map(
                          (item: any, index: number) => {
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
                                  <td className="px-4 py-3">
                                    {item["Subject"]}
                                  </td>
                                  <td className="px-4 py-3">
                                    {item.Status?.toLowerCase().trim() ===
                                    "pass" ? (
                                      <span className="tracking-wide uppercase">
                                        <CircleCheck
                                          size={16}
                                          className="text-green-600 inline-block mr-1"
                                        />
                                        PASS
                                      </span>
                                    ) : (
                                      <span className="tracking-wide uppercase">
                                        <CircleX
                                          size={16}
                                          className="text-red-600 inline-block mr-1"
                                        />
                                        FAIL
                                      </span>
                                    )}
                                  </td>
                                  <td className="px-4 py-3 text-right">
                                    <DropdownMenu>
                                      <DropdownMenuTrigger className="focus:outline-none">
                                        <MoreVertical className="h-5 w-5 text-gray-600 cursor-pointer" />
                                      </DropdownMenuTrigger>
                                      <DropdownMenuContent align="end">
                                        <DropdownMenuItem
                                          onClick={() =>
                                            console.log(
                                              "Download clicked for:",
                                              item["CIS.NO"]
                                            )
                                          }
                                        >
                                          Download
                                        </DropdownMenuItem>
                                        <DropdownMenuItem
                                          className="text-red-600"
                                          onClick={() =>
                                            console.log(
                                              "Delete clicked for:",
                                              item["CIS.NO"]
                                            )
                                          }
                                        >
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
                                        <div className="whitespace-pre-line">
                                          {item["Subject"]}
                                        </div>

                                        <div className="font-semibold">
                                          Description:
                                        </div>
                                        <div className="whitespace-pre-line">
                                          {item["Description"]}
                                        </div>

                                        <div className="font-semibold">
                                          Remediation:
                                        </div>
                                        <div className="whitespace-pre-line">
                                          {item["Remediation"]}
                                        </div>
                                      </div>
                                    </td>
                                  </tr>
                                )}
                              </React.Fragment>
                            );
                          }
                        )
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
