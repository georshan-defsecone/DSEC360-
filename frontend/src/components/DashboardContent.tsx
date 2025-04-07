import { Card, CardContent } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"

export default function DashboardContent() {
  return (
    <div className="grid lg:grid-cols-4 gap-4">

      <Card >
        <CardContent className="p-4">
          <h3 className="font-semibold text-gray-700">Category name</h3>
          <div className="mt-2 text-2xl font-bold">12k <span className="text-green-500 text-sm">+432</span></div>
          <div className="text-sm text-gray-500">JAN</div>
        </CardContent>
      </Card>

      <Card >
        <CardContent className="p-4">
          <h3 className="font-semibold text-gray-700">Category</h3>
          <div className="text-3xl font-bold mb-2">1282</div>
          <div className="w-full h-24 bg-gray-200 rounded-lg flex items-end justify-center">
            <span className="text-xs text-gray-500">Chart</span>
          </div>
        </CardContent>
      </Card>

      <Card className=" bg-black text-white">
        <CardContent className="p-4">
          <h3 className="font-semibold mb-2">Progress</h3>
          <div className="text-3xl font-bold">4751</div>
          <Progress value={75} className="mt-4 bg-gray-800 h-2" />
          <div className="text-sm mt-1 text-right">75.5%</div>
        </CardContent>
      </Card>

      <div className="col-span-2">
        <Card className="mt-3 w-2/3">
          <CardContent className="p-4">
            <h3 className="font-semibold mb-4">Category name</h3>
            <div className="text-sm text-gray-500">
              Table (object names, values, dates) goes here
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className=" mt-4">
        <CardContent className="p-4 space-y-4">
          <div className="text-md font-semibold">Category name</div>
          <div className="flex justify-between text-sm">
            <span>Lorem ipsum</span>
            <span>40%</span>
          </div>
          <Progress value={40} />

          <div className="flex justify-between text-sm">
            <span>Dolor</span>
            <span>35%</span>
          </div>
          <Progress value={35} className="bg-green-500" />
        </CardContent>
      </Card>
    </div>
  )
}
