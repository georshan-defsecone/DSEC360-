import { useEffect, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import api from "../api";

import Header from "@/components/Header";
import Sidebar from "@/components/Sidebar";
import ScanPieChart from "@/components/ScanPieChart";

import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

import ReactECharts from "echarts-for-react";

const ProjectScans = () => {
  const { project_id } = useParams();
  const navigate = useNavigate();

  const [scans, setScans] = useState([]);
  const [projectName, setProjectName] = useState("");
  const [searchTerm, setSearchTerm] = useState("");

  const [scanTypeFilters, setScanTypeFilters] = useState<string[]>([]);
  const [selectedScanTypes, setSelectedScanTypes] = useState<string[]>([]);

  useEffect(() => {
    const fetchScans = async () => {
      try {
        const response = await api.get(`scans/project/${project_id}/`);
        setScans(response.data);

        const allTypes = [
          ...new Set(response.data.map((scan: any) => scan.scan_type)),
        ];
        setScanTypeFilters(allTypes);
        setSelectedScanTypes(allTypes); // Preselect all by default
      } catch (err) {
        console.error("Failed to fetch scans", err);
      }
    };

    const fetchProjectName = async () => {
      try {
        const response = await api.get(`project/${project_id}/`);
        setProjectName(response.data.project_name);
      } catch (err) {
        console.error("Failed to fetch project name", err);
      }
    };

    fetchProjectName();
    fetchScans();
  }, [project_id]);

  const toggleScanType = (type: string) => {
    setSelectedScanTypes((prev) =>
      prev.includes(type) ? prev.filter((t) => t !== type) : [...prev, type]
    );
  };

  const goToScan = (scanName: string) => {
    navigate(
      `/scan/scanresult/${encodeURIComponent(projectName)}/${encodeURIComponent(
        scanName
      )}`
    );
  };

  const scanTypeCounts = scans.reduce((acc, scan) => {
    acc[scan.scan_type] = (acc[scan.scan_type] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const scanBarGraphData = scans
    .filter(
      (scan) =>
        scan.scan_data?.complianceCategory &&
        (selectedScanTypes.length === 0 ||
          selectedScanTypes.includes(scan.scan_type))
    )
    .map((scan) => {
      const results = scan.parsed_scan_result || [];
      const counts = results.reduce(
        (acc: { Passed: number; Failed: number }, item: any) => {
          const status = (item.Status || "").toUpperCase();
          if (status === "PASS") acc.Passed += 1;
          else if (status === "FAIL") acc.Failed += 1;
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

  const chartHeight = 400;

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
          {/* ✅ Full-width Bar Chart with Filters */}
          <div className="bg-white border border-gray-200 shadow p-4 relative">
            <h3 className="text-lg font-semibold text-gray-800 mb-2">
              Scan Results Overview
            </h3>

            {/* 🔘 Dynamic Scan Type Filters (as checkboxes above pie chart) */}
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

          {/* ✅ Scan Table and Pie Chart side by side */}
          <div className="flex gap-6">
            {/* Scan Table */}
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
                      <thead className="sticky top-0 z-10 bg-gray-100 text-gray-700 border-b border-gray-400">
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
                          filteredScans.map((scan, i) => (
                            <tr
                              key={i}
                              onClick={() => goToScan(scan.scan_name)}
                              className={`cursor-pointer hover:bg-gray-100 border-b border-gray-100 ${
                                i % 2 === 0 ? "bg-white" : "bg-gray-50"
                              }`}
                            >
                              <td className="py-3 px-4 font-medium border-none">
                                {scan.scan_name}
                              </td>
                              <td className="py-3 px-4 border-none">
                                {scan.scan_author}
                              </td>
                              <td className="py-3 px-4 border-none">
                                {scan.scan_time
                                  ? new Date(scan.scan_time).toLocaleTimeString(
                                      [],
                                      {
                                        hour: "2-digit",
                                        minute: "2-digit",
                                        hour12: true,
                                      }
                                    )
                                  : "N/A"}
                              </td>
                              <td className="py-3 px-4 border-none">
                                {scan.scan_status}
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Pie Chart */}
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
