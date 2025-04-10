// src/utils/auth.ts

export const verifyToken = async (): Promise<boolean> => {
  const token = localStorage.getItem("access");

  if (!token) return false;

  try {
    const res = await fetch("http://localhost:8000/api/token/verify/", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ token }),
    });

    return res.ok; // true if token valid, false otherwise
  } catch (err) {
    return false;
  }
};
