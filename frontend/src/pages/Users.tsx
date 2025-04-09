import Sidebar from "@/components/Sidebar";
import Header from "@/components/Header";
import {
  Table,
  TableBody,
  TableCell,
  TableCaption,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useState,useEffect } from "react";
import axios from 'axios';

const Users = () => {
  const [users,setUsers]=useState([]);
  
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await axios.get('http://localhost:8000/api/users/');
        setUsers(response.data);
        console.log(response.data);
      } catch (error) {
        console.error('Error fetching user data:', error);
      }
    };

    fetchData();
  }, []);


  return (
    <>
      <div className="flex h-screen text-black">
        <Sidebar settings={true} scanSettings={false} homeSettings={false} />
        <div className="flex-1 flex flex-col pr-8 pl-8 ml-64">
          <Header title="Users" />
          <Table className="bg-white text-black">
            <TableCaption>User Info.</TableCaption>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Last Login</TableHead>
                <TableHead className="">Role</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((user) => (
                <TableRow key={user.name}>
                  <TableCell className="font-medium">{user.name}</TableCell>
                  <TableCell>{user.lastlogin}</TableCell>
                  <TableCell>{user.role}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </div>
    </>
  );
};

export default Users;
