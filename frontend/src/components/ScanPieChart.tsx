import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

// Default color palette for non pass/fail types
const COLORS = [
  "#4F46E5", // Indigo
  "#10B981", // Emerald
  "#F59E0B", // Amber
  "#EF4444", // Red
  "#6366F1", // Violet
  "#EC4899", // Pink
];

// Color override for PASS/FAIL types
const PASS_FAIL_COLORS: Record<string, string> = {
  PASS: "#10B981", // Green
  FAIL: "#EF4444", // Red
};

// Tooltip component
const CustomTooltip = ({ active, payload }) => {
  if (active && payload && payload.length) {
    const { name, value } = payload[0];
    return (
      <div className="bg-white p-2 border rounded shadow text-sm text-gray-700">
        <strong>{name}</strong> {value} scans
      </div>
    );
  }
  return null;
};

const ScanPieChart = ({ data }) => {
  const chartData = Object.entries(data).map(([type, count]) => {
    const upperType =
      type.toLowerCase() === "passed"
        ? "PASS"
        : type.toLowerCase() === "failed"
        ? "FAIL"
        : type;
    return { name: upperType, value: count };
  });

  const total = chartData.reduce((acc, item) => acc + item.value, 0);

  const isPassFail =
    chartData.length <= 2 &&
    chartData.every((entry) =>
      ["pass", "fail"].includes(entry.name.toLowerCase())
    );

  if (chartData.length === 0) {
    return (
      <div className="text-gray-500 text-sm text-center mt-8">
        No scan data available
      </div>
    );
  }

  return (
    <div className="w-full">
      <h2 className="text-lg font-semibold text-center mb-4 text-gray-700">
        Audit Summary
      </h2>

      <div className="relative w-full h-[240px]">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={chartData}
              dataKey="value"
              nameKey="name"
              cx="50%"
              cy="50%"
              outerRadius={75}
              innerRadius={40}
              labelLine={false}
              stroke="#fff"
              strokeWidth={1}
              isAnimationActive={true}
              animationDuration={800}
              animationEasing="ease-out"
            >
              {chartData.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={
                    isPassFail
                      ? PASS_FAIL_COLORS[entry.name] || "#999"
                      : COLORS[index % COLORS.length]
                  }
                  style={{
                    filter: "drop-shadow(1px 1px 2px rgba(0,0,0,0.15))",
                    transition: "transform 0.3s ease",
                  }}
                />
              ))}
            </Pie>
            <Tooltip content={<CustomTooltip />} />
          </PieChart>
        </ResponsiveContainer>

        {/* Total Scans in the center */}
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-center">
          <div className="text-lg font-semibold text-gray-700">{total}</div>
          <div className="text-xs text-gray-500">Total Scans</div>
        </div>
      </div>

      {/* Legend with aligned values */}
      <div className="mt-5 w-full px-6 text-sm text-gray-700">
        {chartData.map((entry, index) => (
          <div key={index} className="flex items-center mb-1.5">
            <div
              className="w-3 h-3 rounded-full mr-2"
              style={{
                backgroundColor: isPassFail
                  ? PASS_FAIL_COLORS[entry.name] || "#999"
                  : COLORS[index % COLORS.length],
              }}
            />
            <div className="flex w-full">
              <span className="w-28 font-medium">{entry.name}</span>
              <span className="text-gray-600">{entry.value}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ScanPieChart;
