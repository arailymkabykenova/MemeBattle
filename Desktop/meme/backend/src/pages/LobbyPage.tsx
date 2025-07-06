import React, { useEffect, useState, useCallback } from "react";
import { Paper, Button, Typography, Avatar, CircularProgress } from "@mui/material";
import { motion, AnimatePresence } from "framer-motion";
import axios from "axios";
import { useWebSocket } from "../hooks/useWebSocket";

const API_URL = "http://localhost:8000";

interface Player {
  id: number;
  nickname: string;
  is_creator?: boolean;
  is_ready?: boolean;
}

interface LobbyPageProps {
  token: string;
  roomId: number;
  userId: number;
  onStartGame: () => void;
  onLeave: () => void;
}

export default function LobbyPage({ token, roomId, userId, onStartGame, onLeave }: LobbyPageProps) {
  const [players, setPlayers] = useState<Player[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [isCreator, setIsCreator] = useState(false);
  const [starting, setStarting] = useState(false);

  // WebSocket обработка событий
  const handleWsMessage = useCallback((msg: any) => {
    if (msg.type === "player_joined" || msg.type === "player_left") {
      setPlayers(msg.players || []);
    }
    if (msg.type === "start_game") {
      onStartGame();
    }
  }, [onStartGame]);

  useWebSocket(
    `${API_URL.replace('http', 'ws')}/ws/rooms/${roomId}?token=${token}`,
    handleWsMessage
  );

  useEffect(() => {
    fetchRoom();
    // eslint-disable-next-line
  }, []);

  const fetchRoom = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await axios.get(`${API_URL}/rooms/${roomId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const room = res.data;
      setPlayers(room.participants || []);
      setIsCreator(room.creator_id === userId);
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка загрузки комнаты");
    } finally {
      setLoading(false);
    }
  };

  const handleStartGame = async () => {
    setStarting(true);
    try {
      await axios.post(`${API_URL}/rooms/${roomId}/start-game`, {}, {
        headers: { Authorization: `Bearer ${token}` },
      });
      // onStartGame будет вызван по WebSocket событию
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка старта игры");
    } finally {
      setStarting(false);
    }
  };

  return (
    <div style={{ maxWidth: 500, margin: "60px auto", padding: 24 }}>
      <Paper elevation={3} sx={{ p: 3, borderRadius: 4, background: 'rgba(255,255,255,0.85)' }}>
        <Typography variant="h4" fontWeight={700} mb={2} align="center" color="primary">
          Лобби комнаты #{roomId}
        </Typography>
        {loading ? (
          <div style={{ textAlign: "center", margin: 40 }}><CircularProgress /></div>
        ) : error ? (
          <Typography color="error" align="center">{error}</Typography>
        ) : (
          <>
            <AnimatePresence>
              <div style={{ display: "flex", flexDirection: "column", gap: 16, marginBottom: 24 }}>
                {players.map((player) => (
                  <motion.div
                    key={player.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -20 }}
                    transition={{ duration: 0.4 }}
                  >
                    <Paper elevation={1} sx={{ display: 'flex', alignItems: 'center', p: 1.5, borderRadius: 3, background: 'rgba(255,255,255,0.7)' }}>
                      <Avatar sx={{ bgcolor: player.is_creator ? 'primary.main' : 'secondary.main', mr: 2 }}>
                        {player.nickname[0]?.toUpperCase()}
                      </Avatar>
                      <Typography variant="h6" fontWeight={player.is_creator ? 700 : 500} color={player.is_creator ? 'primary' : 'text.primary'}>
                        {player.nickname} {player.is_creator && <span style={{ fontSize: 14, color: '#FFB6B9' }}>(создатель)</span>}
                      </Typography>
                    </Paper>
                  </motion.div>
                ))}
              </div>
            </AnimatePresence>
            {isCreator && (
              <Button
                variant="contained"
                size="large"
                onClick={handleStartGame}
                disabled={starting}
                sx={{ width: '100%', mb: 2, fontSize: 20, py: 1.5 }}
              >
                {starting ? "Запуск..." : "Начать игру"}
              </Button>
            )}
            <Button variant="outlined" color="secondary" onClick={onLeave} sx={{ width: '100%' }}>
              Выйти из комнаты
            </Button>
          </>
        )}
      </Paper>
    </div>
  );
} 