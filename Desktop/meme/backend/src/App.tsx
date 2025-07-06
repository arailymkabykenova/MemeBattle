import React, { useState } from "react";
import { BrowserRouter as Router, Routes, Route, useLocation, useNavigate } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import AuthPage from "./pages/AuthPage";
import ProfilePage from "./pages/ProfilePage";
import HomePage from "./pages/HomePage";
import RoomsPage from "./pages/RoomsPage";
import LobbyPage from "./pages/LobbyPage";
import GamePage from "./pages/GamePage";
import CardsPage from "./pages/CardsPage";
import ProfileViewPage from "./pages/ProfileViewPage";

// Вспомогательный компонент для анимированных переходов
function AnimatedRoutes({ token, setToken, userId, setUserId }: any) {
  const location = useLocation();
  const navigate = useNavigate();
  const [roomId, setRoomId] = useState<number | null>(null);
  const [roundId, setRoundId] = useState<number | null>(null);

  // Пример: после авторизации сохраняем userId (можно расширить)
  const handleAuth = (token: string) => {
    setToken(token);
    // Можно получить userId из токена или запроса /auth/me
    navigate("/profile-setup");
  };

  const handleProfileComplete = () => {
    navigate("/home");
  };

  const handleGoToRooms = () => navigate("/rooms");
  const handleGoToCards = () => navigate("/cards");
  const handleGoToProfile = () => navigate("/profile");
  const handleLogout = () => {
    setToken("");
    setUserId(null);
    navigate("/");
  };

  const handleEnterLobby = (roomId: number) => {
    setRoomId(roomId);
    navigate(`/lobby/${roomId}`);
  };

  const handleStartGame = () => {
    // Здесь можно получить roundId через API, для примера просто 1
    setRoundId(1);
    navigate(`/game/${roundId || 1}`);
  };

  const handleGameEnd = () => {
    navigate("/home");
  };

  return (
    <AnimatePresence mode="wait">
      <Routes location={location} key={location.pathname}>
        <Route
          path="/"
          element={
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.4 }}>
              <AuthPage onAuth={handleAuth} />
            </motion.div>
          }
        />
        <Route
          path="/profile-setup"
          element={
            <motion.div initial={{ opacity: 0, x: 40 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -40 }} transition={{ duration: 0.4 }}>
              <ProfilePage token={token} onProfileComplete={handleProfileComplete} />
            </motion.div>
          }
        />
        <Route
          path="/home"
          element={
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -40 }} transition={{ duration: 0.4 }}>
              <HomePage
                onGoToRooms={handleGoToRooms}
                onGoToCards={handleGoToCards}
                onGoToProfile={handleGoToProfile}
                onLogout={handleLogout}
                user={{ nickname: "Игрок" }}
              />
            </motion.div>
          }
        />
        <Route
          path="/rooms"
          element={
            <motion.div initial={{ opacity: 0, x: 40 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -40 }} transition={{ duration: 0.4 }}>
              <RoomsPage token={token} onEnterLobby={handleEnterLobby} />
            </motion.div>
          }
        />
        <Route
          path="/lobby/:roomId"
          element={
            <motion.div initial={{ opacity: 0, scale: 0.98 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.98 }} transition={{ duration: 0.4 }}>
              {roomId && userId && (
                <LobbyPage token={token} roomId={roomId} userId={userId} onStartGame={handleStartGame} onLeave={handleGoToRooms} />
              )}
            </motion.div>
          }
        />
        <Route
          path="/game/:roundId"
          element={
            <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -40 }} transition={{ duration: 0.4 }}>
              {roundId && userId && (
                <GamePage token={token} roundId={roundId} userId={userId} onGameEnd={handleGameEnd} />
              )}
            </motion.div>
          }
        />
        <Route
          path="/cards"
          element={
            <motion.div initial={{ opacity: 0, x: 40 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -40 }} transition={{ duration: 0.4 }}>
              <CardsPage token={token} />
            </motion.div>
          }
        />
        <Route
          path="/profile"
          element={
            <motion.div initial={{ opacity: 0, scale: 0.98 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.98 }} transition={{ duration: 0.4 }}>
              <ProfileViewPage token={token} onLogout={handleLogout} />
            </motion.div>
          }
        />
      </Routes>
    </AnimatePresence>
  );
}

export default function App() {
  const [token, setToken] = useState<string>("");
  const [userId, setUserId] = useState<number | null>(null);

  return (
    <Router>
      <AnimatedRoutes token={token} setToken={setToken} userId={userId} setUserId={setUserId} />
    </Router>
  );
} 