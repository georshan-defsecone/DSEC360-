import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";
import api from "../api";

const Myaccounts = () => {
  const [username, setUserName] = useState("");
  const [useremail, setUserEmail] = useState("");
  const [role, setRole] = useState("User");

  const [showEditCard, setShowEditCard] = useState(false);

  const [newUsername, setNewUsername] = useState("");
  const [newEmail, setNewEmail] = useState("");

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await api.get("users/userinfo");
        setUserName(response.data.username);
        setUserEmail(response.data.email);
        setRole(response.data.is_admin ? "Administrator" : "User");
      } catch (error) {
        console.error("Error fetching user data:", error);
      }
    };

    fetchData();
  }, []);

  const handleSaveEdit = async () => {
    const updatedData: any = {};
    if (newUsername) updatedData.username = newUsername;
    if (newEmail) updatedData.email = newEmail;

    try {
      if (Object.keys(updatedData).length > 0) {
        const response = await api.put("updateuser/", updatedData);
        setUserName(response.data.username);
        setUserEmail(response.data.email);
      }

      if (currentPassword || newPassword || confirmPassword) {
        if (!currentPassword || !newPassword || !confirmPassword) {
          alert("Please fill out all password fields.");
          return;
        }

        if (newPassword !== confirmPassword) {
          alert("Passwords do not match");
          return;
        }

        await api.put("updateuser/password", {
          current_password: currentPassword,
          new_password: newPassword,
        });

        setCurrentPassword("");
        setNewPassword("");
        setConfirmPassword("");
      }

      setShowEditCard(false);
    } catch (error) {
      console.error("Error updating user information:", error);
      alert("Failed to update information.");
    }
  };

  const handleEditCardOpen = () => {
    setNewUsername("");
    setNewEmail("");
    setCurrentPassword("");
    setNewPassword("");
    setConfirmPassword("");
    setShowEditCard(true);
  };

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase();
  };

  return (
    <div className="flex h-screen text-black pt-16 relative">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />
      <div className="flex-1 flex flex-col ml-64 p-8">
        <Header title="My Account" />

        {/* Account Info Card */}
        <Card className="w-[85%] mt-10 ml-4 rounded-none shadow-2xl">
          <CardContent className="w-full p-4 px-12">
            <div className="flex items-center gap-6">
              <div className="w-24 h-24 mb-12 mr-5 rounded-full bg-gradient-to-br from-blue-500 to-gray-600 flex items-center justify-center text-white text-3xl font-bold shadow-lg shrink-0">
                {getInitials(username || "U")}
              </div>

              <div className="space-y-2 w-full">
                <div className="flex items-center">
                  <div className="w-28 text-gray-600 text-base font-semibold">
                    Username
                  </div>
                  <div className="text-gray-800 text-base font-medium">
                    {username}
                  </div>
                </div>

                <div className="flex items-center">
                  <div className="w-28 text-gray-600 text-base font-semibold">
                    Email
                  </div>
                  <div className="text-gray-800 text-base font-medium">
                    {useremail}
                  </div>
                </div>

                <div className="flex items-center">
                  <div className="w-28 text-gray-600 text-base font-semibold">
                    Role
                  </div>
                  <span className="bg-gray-200 text-gray-800 px-3 py-1 rounded-full text-sm font-medium">
                    {role}
                  </span>
                </div>

                <div className="pt-4">
                  <Button
                    onClick={handleEditCardOpen}
                    className="bg-black text-white hover:bg-gray-800 cursor-pointer rounded-none"
                  >
                    Edit
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Edit Modal */}
      {showEditCard && (
        <div className="absolute inset-0 flex items-center justify-center z-50 ">
          <div className="pointer-events-auto w-full max-w-3xl">
            <Card className="w-full shadow-2xl relative rounded-none">
              <CardContent className="p-8">
                <button
                  className="absolute top-3 right-3 text-gray-500 hover:text-black cursor-pointer rounded-none"
                  onClick={() => setShowEditCard(false)}
                >
                  <X />
                </button>
                <h2 className="text-xl font-semibold text-center mb-6">
                  Edit User Info
                </h2>

                <div className="flex flex-col md:flex-row gap-8">
                  {/* Left: Profile Info */}
                  <div className="flex-1 space-y-4">
                    {/* Username */}
                    <div className="space-y-1">
                      <label className="text-sm text-gray-600">Username</label>
                      <Input
                        type="text"
                        value={newUsername}
                        onChange={(e) => setNewUsername(e.target.value)}
                        placeholder="Enter new username"
                      />
                    </div>

                    {/* Email */}
                    <div className="space-y-1">
                      <label className="text-sm text-gray-600 ">Email</label>
                      <Input
                        type="email"
                        value={newEmail}
                        onChange={(e) => setNewEmail(e.target.value)}
                        placeholder="Enter new email"
                      />
                    </div>
                  </div>

                  {/* Right: Password Update */}
                  <div className="flex-1 space-y-4">
                    <h3 className="text-md font-semibold text-gray-700">
                      Change Password (Optional)
                    </h3>

                    <div className="space-y-1">
                      <label className="text-sm text-gray-600">
                        Current Password
                      </label>
                      <Input
                        type="password"
                        value={currentPassword}
                        onChange={(e) => setCurrentPassword(e.target.value)}
                        placeholder="Enter current password"
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="text-sm text-gray-600">New Password</label>
                      <Input
                        type="password"
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        placeholder="Enter new password"
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="text-sm text-gray-600">
                        Confirm New Password
                      </label>
                      <Input
                        type="password"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        placeholder="Retype new password"
                      />
                    </div>
                  </div>
                </div>

                <div className="pt-6">
                  <Button
                    onClick={handleSaveEdit}
                    className="bg-black text-white hover:bg-gray-800 w-full cursor-pointer rounded-none"
                  >
                    Save Changes
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      )}
    </div>
  );
};

export default Myaccounts;
