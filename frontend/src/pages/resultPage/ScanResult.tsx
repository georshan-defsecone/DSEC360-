import { useParams } from "react-router-dom";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import api from "../api";
import Papa from "papaparse";
import { useEffect, useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { Card } from "@/components/ui/card"; // Adjust path based on your setup
import { CheckCircle, XCircle } from "lucide-react"; // Icons for pass/fail

const ScanResult = () => {
  const { projectName, scanName } = useParams<{
    projectName: string;
    scanName: string;
  }>();

  const [summary, setSummary] = useState<{ pass: number; fail: number }>({
    pass: 0,
    fail: 0,
  });
  const [auditItems, setAuditItems] = useState<
    { name: string; status: string }[]
  >([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

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
        const text = await response.data.text();

        const parsed = Papa.parse(text, {
          header: true,
          skipEmptyLines: true,
        });

        const data = parsed.data as any[];

        let pass = 0;
        let fail = 0;
        const audits: { name: string; status: string }[] = [];

        data.forEach((row) => {
          const status = row["Result"]?.toLowerCase().trim();
          const name = row["Subject"]?.trim() || row["Name"]?.trim();

          if (status === "pass") pass++;
          else if (status === "fail") fail++;

          if (name) {
            audits.push({ name, status });
          }
        });

        setSummary({ pass, fail });
        setAuditItems(audits);
      } catch (err: any) {
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
          <div className="flex gap-6 mt-8">
            {/* Left side: Bar Chart */}
            <div className="w-1/3 h-80 ">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={[
                    { name: "Passed", count: summary.pass },
                    { name: "Failed", count: summary.fail },
                  ]}
                >
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#3b82f6" />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* Right side: Audit List */}
            <div className="w-2/3">
              <Card className="p-4 shadow-2xl">
                <h3 className="text-lg font-semibold mb-4">Audit Results</h3>
                <div className="max-h-80 overflow-y-auto pr-2 space-y-3">
                  {auditItems.length > 0 ? (
                    auditItems.map((item, index) => (
                      <div
                        key={index}
                        className="flex items-center justify-between"
                      >
                        <span className="text-sm">{item.name}</span>
                        {item.status === "pass" ? (
                          <CheckCircle className="text-green-500 w-5 h-5" />
                        ) : (
                          <XCircle className="text-red-500 w-5 h-5" />
                        )}
                      </div>
                    ))
                  ) : (
                    <p className="text-gray-500">No audit data available.</p>
                  )}
                </div>
              </Card>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ScanResult;
