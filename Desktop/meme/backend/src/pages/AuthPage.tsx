import React, { useState } from "react";
import axios from "axios";

const API_URL = "http://localhost:8000";

export default function AuthPage({ onAuth }: { onAuth: (token: string) => void }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleAuth = async () => {
    setLoading(true);
    setError("");
    try {
      let device_id = localStorage.getItem("device_id");
      if (!device_id) {
        device_id = Math.random().toString(36).substring(2, 15);
        localStorage.setItem("device_id", device_id);
      }
      const res = await axios.post(`${API_URL}/auth/device`, { device_id });
      onAuth(res.data.access_token);
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка авторизации");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ textAlign: "center", marginTop: 100 }}>
      <h2>Вход в игру</h2>
      <button onClick={handleAuth} disabled={loading}>
        {loading ? "Входим..." : "Войти"}
      </button>
      {error && <div style={{ color: "red", marginTop: 10 }}>{error}</div>}
    </div>
  );
} 