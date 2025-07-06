import React, { useState } from "react";
import axios from "axios";

const API_URL = "http://localhost:8000";

interface ProfilePageProps {
  token: string;
  onProfileComplete: () => void;
}

export default function ProfilePage({ token, onProfileComplete }: ProfilePageProps) {
  const [nickname, setNickname] = useState("");
  const [birthDate, setBirthDate] = useState("");
  const [gender, setGender] = useState("female");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await axios.post(
        `${API_URL}/auth/complete-profile`,
        {
          nickname,
          birth_date: birthDate,
          gender,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      onProfileComplete();
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка заполнения профиля");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 400, margin: "60px auto", padding: 24, border: "1px solid #eee", borderRadius: 8 }}>
      <h2>Настройка профиля</h2>
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: 16 }}>
          <label>Никнейм:<br />
            <input value={nickname} onChange={e => setNickname(e.target.value)} required style={{ width: "100%" }} />
          </label>
        </div>
        <div style={{ marginBottom: 16 }}>
          <label>Дата рождения:<br />
            <input type="date" value={birthDate} onChange={e => setBirthDate(e.target.value)} required style={{ width: "100%" }} />
          </label>
        </div>
        <div style={{ marginBottom: 16 }}>
          <label>Пол:<br />
            <select value={gender} onChange={e => setGender(e.target.value)} style={{ width: "100%" }}>
              <option value="female">Женский</option>
              <option value="male">Мужской</option>
            </select>
          </label>
        </div>
        <button type="submit" disabled={loading} style={{ width: "100%", padding: 8 }}>
          {loading ? "Сохраняем..." : "Сохранить профиль"}
        </button>
        {error && <div style={{ color: "red", marginTop: 10 }}>{error}</div>}
      </form>
    </div>
  );
} 