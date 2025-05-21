import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { X } from 'lucide-react';
import api from "../api";
import { CircleUserRound } from "lucide-react";
import { Pencil } from "lucide-react";
const Myaccounts = () => {
  const [username, setUserName] = useState("");
  const [useremail, setUserEmail] = useState("");
  const [role, setRole] = useState("User");
  const [showPasswordCard, setShowPasswordCard] = useState(false);
  const [showEditCard, setShowEditCard] = useState(false); // State to show the edit modal

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [newUsername, setNewUsername] = useState(""); // New username for editing
  const [newEmail, setNewEmail] = useState(""); // New email for editing

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

  const handleSavePassword = () => {
    if (newPassword !== confirmPassword) {
      alert("Passwords do not match");
      return;
    }
    // Add your password update API call here
    console.log("Password updated:", {
      currentPassword,
      newPassword,
      confirmPassword,
    });

    // Clear fields and close
    setCurrentPassword("");
    setNewPassword("");
    setConfirmPassword("");
    setShowPasswordCard(false);
  };

  const handleSaveEdit = async () => {
    const updatedData = {};

    // If username is provided, set it to updatedData
    if (newUsername) updatedData.username = newUsername;
    // If email is provided, set it to updatedData
    if (newEmail) updatedData.email = newEmail;

    try {
      // Make an API call to update the username and/or email
      const response = await api.put("updateuser/", updatedData);
      setUserName(response.data.username);
      setUserEmail(response.data.email);

      // Close the edit modal
      setShowEditCard(false);
    } catch (error) {
      console.error("Error updating user information:", error);
      alert("Failed to update information.");
    }
  };

  // Reset values when the Edit modal is shown (to ensure the input fields are empty and only show placeholders)
  const handleEditCardOpen = () => {
    setNewUsername("");  // Clear the current username value
    setNewEmail("");     // Clear the current email value
    setShowEditCard(true);
  };

  return (
    <div className="flex h-screen text-black relative pt-16">
      <Sidebar settings={true} scanSettings={false} homeSettings={false} />

      <div className="flex-1 flex flex-col ml-64 p-8">
        <Header title="My Account" />

        <Card className="min-h-130 relative">
          <CardContent className="p-8">
            <div className="flex items-start gap-8">
              {/* Profile Icon */}
              {/* Profile Icon */}
              <CircleUserRound className="w-32 h-32 text-gray-600 mt-1" />
              {/* User Info and Button */}
              <div className="w-full max-w-md space-y-4">
                {/* Username Row */}
                <div className="flex items-center border-b pb-2">
                  <div className="w-32 text-gray-500">Username</div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-gray-800">
                      {username}
                    </span>
                    <button className="text-gray-500 hover:text-black transition">
                      <Pencil />
                    </button>
                  </div>
                </div>

                {/* Email Row */}
                <div className="flex items-center border-b pb-2">
                  <div className="w-32 text-gray-500">Email</div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-gray-800">
                      {useremail}
                    </span>
                    <button className="text-gray-500 hover:text-black transition">
                      <Pencil/>
                    </button>
                  </div>
                </div>

                {/* Role Row */}
                <div className="flex items-center">
                  <div className="w-32 text-gray-500">Role</div>
                  <span className="font-medium text-gray-800">{role}</span>
                </div>

                {/* Change Password Button */}
                <div className="pt-6">
                  <button
                    className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition"
                    onClick={() => setShowPasswordCard(true)}
                  >
                    Change Password
                  </button>
                </div>
              </div>
            </div>
          </CardContent>

          {/* Edit Button at the bottom right of the card */}
          <div className="absolute bottom-4 right-4">
            <button
              className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition"
              onClick={handleEditCardOpen} // Show the Edit Card
            >
              Edit
            </button>
          </div>
        </Card>
      </div>

      {/* Change Password Popup Card */}
      {showPasswordCard && (
        <div className="absolute inset-0 flex items-center justify-center z-50 pointer-events-none">
          <div className="pointer-events-auto w-xl">
            <Card className="w-full max-w-lg shadow-xl ml-15 relative">
              <CardContent className="p-8 space-y-6">
                {/* Close button */}
                <button
                  className="absolute top-3 right-3 text-gray-500 hover:text-black"
                  onClick={() => setShowPasswordCard(false)}
                ><X/></button>

                <h2 className="text-xl font-semibold text-center">Change Password</h2>

                {/* Inputs */}
                <div className="space-y-1">
                  <label className="text-sm text-gray-600">Current Password</label>
                  <Input
                    type="password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    placeholder="Enter your current password"
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
                  <label className="text-sm text-gray-600">Confirm Password</label>
                  <Input
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Retype new password"
                  />
                </div>

                {/* Save button */}
                <div className="pt-4">
                  <Button
                    onClick={handleSavePassword}
                    className="bg-black text-white hover:bg-gray-800 w-full"
                  >
                    Save
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      )}

      {/* Edit User Info Popup Card */}
      {showEditCard && (
        <div className="absolute inset-0 flex items-center justify-center z-50 pointer-events-none">
          <div className="pointer-events-auto w-xl">
            <Card className="w-full max-w-lg shadow-xl ml-15 relative">
              <CardContent className="p-8 space-y-6">
                {/* Close button */}
                <button
                  className="absolute top-3 right-3 text-gray-500 hover:text-black"
                  onClick={() => setShowEditCard(false)}
                >
                  <X />
                </button>

                <h2 className="text-xl font-semibold text-center">Edit User Info</h2>

                {/* Inputs for username and email */}
                <div className="space-y-1">
                  <label className="text-sm text-gray-600">Username</label>
                  <Input
                    type="text"
                    value={newUsername}
                    onChange={(e) => setNewUsername(e.target.value)}
                    placeholder="Enter new username (Leave blank to keep current)"
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-sm text-gray-600">Email</label>
                  <Input
                    type="email"
                    value={newEmail}
                    onChange={(e) => setNewEmail(e.target.value)}
                    placeholder="Enter new email (Leave blank to keep current)"
                  />
                </div>

                {/* Save button */}
                <div className="pt-4">
                  <Button
                    onClick={handleSaveEdit}
                    className="px-4 py-2 bg-black text-white rounded hover:bg-gray-800 transition"
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

