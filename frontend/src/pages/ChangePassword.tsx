import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

const ChangePassword = () => {
  return (
    <div className="flex h-screen text-black">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col ml-64 p-8">
        {/* Header at the top */}
        <Header title="Change Password" />

        {/* Content wrapper fills remaining space and centers card */}
        <div className="flex-1 flex items-center justify-center">
          <Card className="w-full max-w-md shadow-lg">
            <CardContent className="p-8 space-y-6">
              {/* Current Password */}
              <div className="space-y-1">
                <label className="text-sm text-gray-600">Current Password</label>
                <Input
                  type="password"
                  placeholder="Enter your current password"
                  className="w-full"
                />
              </div>

              {/* New Password */}
              <div className="space-y-1">
                <label className="text-sm text-gray-600">New Password</label>
                <Input
                  type="password"
                  placeholder="Enter new password"
                  className="w-full"
                />
              </div>

              {/* Retype Password */}
              <div className="space-y-1">
                <label className="text-sm text-gray-600">Retype New Password</label>
                <Input
                  type="password"
                  placeholder="Retype new password"
                  className="w-full"
                />
              </div>

              {/* Submit Button */}
              <div className="pt-4">
                <Button className="bg-black text-white hover:bg-gray-800 w-full">
                  Submit
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default ChangePassword;
