import React from "react";

interface HomePageProps {
  onGoToRooms: () => void;
  onGoToCards: () => void;
  onGoToProfile: () => void;
  onLogout: () => void;
  user?: { nickname?: string };
}

export default function HomePage({ onGoToRooms, onGoToCards, onGoToProfile, onLogout, user }: HomePageProps) {
  return (
    <div style={{ maxWidth: 400, margin: "60px auto", padding: 24, border: "1px solid #eee", borderRadius: 8, textAlign: "center" }}>
      <h2>Добро пожаловать{user?.nickname ? `, ${user.nickname}` : "!"}</h2>
      <div style={{ display: "flex", flexDirection: "column", gap: 16, marginTop: 32 }}>
        <button onClick={onGoToRooms} style={{ padding: 12, fontSize: 18 }}>Играть</button>
        <button onClick={onGoToCards} style={{ padding: 12, fontSize: 18 }}>Мои карты</button>
        <button onClick={onGoToProfile} style={{ padding: 12, fontSize: 18 }}>Профиль</button>
        <button onClick={onLogout} style={{ padding: 12, fontSize: 18, background: '#eee', color: '#333' }}>Выйти</button>
      </div>
    </div>
  );
} 