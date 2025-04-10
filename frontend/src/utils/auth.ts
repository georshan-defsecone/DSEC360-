import axios from "axios";

export const verifyToken = async (): Promise<boolean> => {
  const token = localStorage.getItem("access");

  if (!token) return false;

  try {
    const res = await axios.post("http://localhost:8000/api/token/verify/", {
      token: token,
    });

    return res.status === 200; // token is valid
  } catch (err) {
    return false; // token is invalid or request failed
  }
};
