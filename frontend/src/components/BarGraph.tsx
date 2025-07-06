import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  LabelList,
  Cell,
} from "recharts";

interface BarGraphProps {
  data: { name: string; count: number }[];
}

const BarGraph: React.FC<BarGraphProps> = ({ data }) => {
  const barColors: Record<string, string> = {
    Passed: "#22c55e", // green
    Failed: "#ef4444", // red
  };

  return (
    <div className="h-28 w-full">
      <ResponsiveContainer width="75%" height="100%">
        <BarChart
          layout="vertical"
          data={data}
          margin={{ top: 10, right: 30, left: 30, bottom: 5 }}
          barCategoryGap={15}
        >
          <XAxis
            type="number"
            axisLine={{ stroke: "#9ca3af", strokeWidth: 1 }}
            tick={false}
            tickLine={false}
          />
          <YAxis
            type="category"
            dataKey="name"
            axisLine={{ stroke: "#9ca3af", strokeWidth: 1 }}
            tickLine={false}
            tick={{ fontSize: 14, fill: "#374151", fontWeight: 600 }} // ✅ Show labels
          />
          <Tooltip
            cursor={{ fill: "#f9fafb" }}
            contentStyle={{
              backgroundColor: "#ffffff",
              border: "1px solid #e5e7eb",
              borderRadius: "6px",
              fontSize: "13px",
              color: "#111827",
            }}
          />
          <Bar
            dataKey="count"
            radius={0}
            barSize={14}
            isAnimationActive={true}
          >
            {data.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={barColors[entry.name] || "#60a5fa"} // fallback: blue
              />
            ))}
            <LabelList
              dataKey="count"
              position="right"
              style={{ fill: "#111827", fontSize: 14, fontWeight: 600 }}
            />
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default BarGraph;
