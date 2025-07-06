import React, { useEffect, useState } from "react";
import axios from "axios";

const API_URL = "http://localhost:8000";

interface Room {
  id: number;
  max_players: number;
  is_public: boolean;
  code?: string;
  status: string;
  participants_count?: number;
}

interface RoomsPageProps {
  token: string;
  onEnterLobby: (roomId: number) => void;
}

export default function RoomsPage({ token, onEnterLobby }: RoomsPageProps) {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [maxPlayers, setMaxPlayers] = useState(3);
  const [isPublic, setIsPublic] = useState(true);
  const [joinCode, setJoinCode] = useState("");
  const [joinError, setJoinError] = useState("");

  useEffect(() => {
    fetchRooms();
    // eslint-disable-next-line
  }, []);

  const fetchRooms = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await axios.get(`${API_URL}/rooms/available`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setRooms(res.data);
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка загрузки комнат");
    } finally {
      setLoading(false);
    }
  };

  const handleCreateRoom = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await axios.post(
        `${API_URL}/rooms/`,
        {
          max_players: maxPlayers,
          is_public: isPublic,
          generate_code: !isPublic,
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setShowCreate(false);
      onEnterLobby(res.data.id);
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка создания комнаты");
    } finally {
      setLoading(false);
    }
  };

  const handleJoinByCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setJoinError("");
    try {
      const res = await axios.post(
        `${API_URL}/rooms/join-by-code`,
        { room_code: joinCode },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      onEnterLobby(res.data.id);
    } catch (e: any) {
      setJoinError(e.response?.data?.detail || "Ошибка входа по коду");
    }
  };

  return (
    <div style={{ maxWidth: 600, margin: "40px auto", padding: 24 }}>
      <h2>Доступные комнаты</h2>
      <button onClick={fetchRooms} disabled={loading} style={{ marginBottom: 16 }}>
        Обновить список
      </button>
      {error && <div style={{ color: "red", marginBottom: 10 }}>{error}</div>}
      <ul style={{ listStyle: "none", padding: 0 }}>
        {rooms.map((room) => (
          <li key={room.id} style={{ border: "1px solid #eee", borderRadius: 8, marginBottom: 12, padding: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <b>Комната #{room.id}</b> ({room.is_public ? "Публичная" : "Приватная"})<br />
              Мест: {room.max_players} | Статус: {room.status}
            </div>
            <button onClick={() => onEnterLobby(room.id)} style={{ padding: 8 }}>Войти</button>
          </li>
        ))}
      </ul>
      <button onClick={() => setShowCreate((v) => !v)} style={{ marginTop: 16 }}>
        {showCreate ? "Отмена" : "Создать комнату"}
      </button>
      {showCreate && (
        <form onSubmit={handleCreateRoom} style={{ marginTop: 16, border: "1px solid #eee", borderRadius: 8, padding: 16 }}>
          <div style={{ marginBottom: 12 }}>
            <label>Тип комнаты: </label>
            <select value={isPublic ? "public" : "private"} onChange={e => setIsPublic(e.target.value === "public")}> 
              <option value="public">Публичная</option>
              <option value="private">Приватная</option>
            </select>
          </div>
          <div style={{ marginBottom: 12 }}>
            <label>Максимум игроков: </label>
            <input type="number" min={3} max={8} value={maxPlayers} onChange={e => setMaxPlayers(Number(e.target.value))} required />
          </div>
          <button type="submit" disabled={loading} style={{ padding: 8 }}>
            {loading ? "Создаём..." : "Создать"}
          </button>
        </form>
      )}
      <div style={{ marginTop: 32, borderTop: "1px solid #eee", paddingTop: 16 }}>
        <h3>Войти по коду (приватная комната)</h3>
        <form onSubmit={handleJoinByCode} style={{ display: "flex", gap: 8 }}>
          <input value={joinCode} onChange={e => setJoinCode(e.target.value)} placeholder="Код комнаты" required style={{ flex: 1 }} />
          <button type="submit">Войти</button>
        </form>
        {joinError && <div style={{ color: "red", marginTop: 8 }}>{joinError}</div>}
      </div>
    </div>
  );
} 