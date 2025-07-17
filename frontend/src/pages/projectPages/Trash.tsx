import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
} from "@/components/ui/dropdown-menu";
import { MoreVertical, ArchiveRestore, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button"; // Make sure Button component is imported
import api from "../api";

export default function Trash() {
  const [trashItems, setTrashItems] = useState<any[]>([]);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<any>(null);

  const fetchTrashData = async () => {
    try {
      const [projectsRes, scansRes] = await Promise.all([
        api.get("projects/trash/"),
        api.get("scans/trashed/"),
      ]);

      const projects = projectsRes.data.map((item: any) => ({
        ...item,
        category: "Project",
      }));
      const scans = scansRes.data.map((item: any) => ({
        ...item,
        category: "Scan",
      }));

      setTrashItems([...projects, ...scans]);
    } catch (error) {
      console.error("Error fetching trash data:", error);
    }
  };

  const restoreItem = async (item: any) => {
    try {
      if (item.category === "Project") {
        await api.put(`project/trash/${item.project_id}/`, { trash: false });
      } else if (item.category === "Scan") {
        await api.put(`scans/${item.scan_id}/trash/`, { trash: false });
      }
      fetchTrashData();
    } catch (err) {
      console.error("Failed to restore item", err);
    }
  };

  const confirmPermanentDelete = async () => {
    if (!deleteTarget) return;
    try {
      if (deleteTarget.category === "Project") {
        await api.delete(`project/trash/delete/${deleteTarget.project_id}/`);
      } else {
        await api.delete(`scan/trash/delete/${deleteTarget.scan_id}/`);
      }
      setShowDeleteModal(false);
      setDeleteTarget(null);
      fetchTrashData();
    } catch (err) {
      console.error("Failed to permanently delete item", err);
    }
  };

  useEffect(() => {
    fetchTrashData();
  }, []);

  return (
    <div className="flex h-screen text-black pt-20">
      <Sidebar settings={false} scanSettings={false} homeSettings={true} />
      <div className="flex-1 flex flex-col ml-64 bg-gray-50">
        <div className="flex justify-between items-center px-6">
          <Header title="Trash" />
        </div>

        <div className="w-full px-6 mt-4">
          <Card className="shadow-lg border border-gray-200 bg-white rounded-none">
            <CardContent className="p-5">
              <ScrollArea className="max-h-[600px]">
                <Table className="table-fixed w-full text-sm border-collapse">
                  <TableHeader className="sticky top-0 z-10 bg-gray-200 text-gray-700 border-b border-gray-400">
                    <TableRow>
                      <TableHead className="w-1/4 text-left px-4 py-2">
                        Name
                      </TableHead>
                      <TableHead className="w-1/4 text-left px-4 py-2">
                        Author
                      </TableHead>
                      <TableHead className="w-1/4 text-left px-4 py-2">
                        Category
                      </TableHead>
                      <TableHead className="w-1/4 text-left px-4 py-2">
                        Actions
                      </TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {trashItems.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={4} className="text-center py-4">
                          No trashed items found.
                        </TableCell>
                      </TableRow>
                    ) : (
                      trashItems.map((item, index) => {
                        const name =
                          item.category === "Project"
                            ? item.project_name
                            : item.scan_name;
                        const author =
                          item.category === "Project"
                            ? item.project_author
                            : item.scan_author;

                        return (
                          <TableRow
                            key={index}
                            className="hover:bg-gray-100 cursor-pointer"
                            onClick={() => {
                              console.log("Clicked item:", item);
                            }}
                          >
                            <TableCell className="w-1/4 py-3 px-4 font-medium truncate">
                              {name}
                            </TableCell>
                            <TableCell className="w-1/4 py-3 px-4 truncate">
                              {author}
                            </TableCell>
                            <TableCell className="w-1/4 py-3 px-4">
                              {item.category}
                            </TableCell>
                            <TableCell className="w-1/4 py-3 px-4">
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <button
                                    className="p-1 rounded hover:bg-gray-200 transition cursor-pointer"
                                    onClick={(e) => e.stopPropagation()}
                                  >
                                    <MoreVertical />
                                  </button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      restoreItem(item);
                                    }}
                                  >
                                    <ArchiveRestore className="mr-2 h-4 w-4 text-green-600" />
                                    Restore
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      setDeleteTarget(item);
                                      setShowDeleteModal(true);
                                    }}
                                    className="text-red-600 hover:bg-red-50"
                                  >
                                    <Trash2 className="mr-2 h-4 w-4 text-red-600" />
                                    Delete Permanently
                                  </DropdownMenuItem>
                                </DropdownMenuContent>
                              </DropdownMenu>
                            </TableCell>
                          </TableRow>
                        );
                      })
                    )}
                  </TableBody>
                </Table>
              </ScrollArea>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="absolute top-0 left-0 right-0 bottom-0 flex items-center justify-center z-50 ">
          <div className="bg-white rounded-md shadow-xl p-6 w-[400px] border border-gray-300">
            <h2 className="text-lg font-semibold mb-2">Are you sure?</h2>
            <p className="text-sm text-gray-600 mb-6">
              This will permanently delete{" "}
              <strong>
                {deleteTarget?.category === "Project"
                  ? deleteTarget?.project_name
                  : deleteTarget?.scan_name}
              </strong>
              . This action cannot be undone.
            </p>
            <div className="flex justify-end gap-4">
              <Button
                variant="outline"
                onClick={() => {
                  setShowDeleteModal(false);
                  setDeleteTarget(null);
                }}
              >
                Cancel
              </Button>
              <Button variant="destructive" onClick={confirmPermanentDelete}>
                Delete Permanently
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
