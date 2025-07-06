import React, { useEffect, useState, useCallback } from "react";
import { Paper, Typography, Button, Grid, CircularProgress, Avatar } from "@mui/material";
import { motion, AnimatePresence } from "framer-motion";
import axios from "axios";
import { useWebSocket } from "../hooks/useWebSocket";

const API_URL = "http://localhost:8000";

interface Card {
  id: number;
  name: string;
  image_url?: string;
  type: string;
}

interface PlayerChoice {
  id: number;
  user_id: number;
  card_id: number;
  card: Card;
}

interface GamePageProps {
  token: string;
  roundId: number;
  userId: number;
  onGameEnd: () => void;
}

export default function GamePage({ token, roundId, userId, onGameEnd }: GamePageProps) {
  const [phase, setPhase] = useState<'situation' | 'choose' | 'vote' | 'results'>('situation');
  const [situation, setSituation] = useState<string>("");
  const [cards, setCards] = useState<Card[]>([]);
  const [selectedCard, setSelectedCard] = useState<number | null>(null);
  const [choices, setChoices] = useState<PlayerChoice[]>([]);
  const [votedCard, setVotedCard] = useState<number | null>(null);
  const [results, setResults] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // WebSocket обработка событий
  const handleWsMessage = useCallback((msg: any) => {
    if (msg.type === "phase_change") {
      setPhase(msg.phase);
    }
    if (msg.type === "choices_update") {
      setChoices(msg.choices || []);
    }
    if (msg.type === "voting_start") {
      setPhase('vote');
      setChoices(msg.choices || []);
    }
    if (msg.type === "results") {
      setPhase('results');
      setResults(msg.data);
    }
    if (msg.type === "situation") {
      setSituation(msg.situation_text);
    }
  }, []);

  useWebSocket(
    `${API_URL.replace('http', 'ws')}/ws/rooms/${roundId}?token=${token}`,
    handleWsMessage
  );

  useEffect(() => {
    fetchSituation();
    // eslint-disable-next-line
  }, []);

  const fetchSituation = async () => {
    setLoading(true);
    setError("");
    try {
      // Получаем ситуацию для раунда
      const res = await axios.get(`${API_URL}/games/rounds/${roundId}/results`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setSituation(res.data.situation_text || "Ситуация не найдена");
      setPhase('choose');
      fetchCards();
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка загрузки ситуации");
    } finally {
      setLoading(false);
    }
  };

  const fetchCards = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${API_URL}/games/my-cards-for-game?count=3`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCards(res.data);
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка загрузки карт");
    } finally {
      setLoading(false);
    }
  };

  const handleChooseCard = async (cardId: number) => {
    setSelectedCard(cardId);
    setLoading(true);
    try {
      await axios.post(
        `${API_URL}/games/rounds/${roundId}/choices`,
        { card_id: cardId },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      // Переход к следующей фазе произойдет по WebSocket событию
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка выбора карты");
    } finally {
      setLoading(false);
    }
  };

  const handleVote = async (choiceId: number) => {
    setVotedCard(choiceId);
    setLoading(true);
    try {
      await axios.post(
        `${API_URL}/games/rounds/${roundId}/votes`,
        { card_id: choiceId },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      // Переход к результатам произойдет по WebSocket событию
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка голосования");
    } finally {
      setLoading(false);
    }
  };

  // UI
  return (
    <div style={{ maxWidth: 700, margin: "40px auto", padding: 24 }}>
      <Paper elevation={4} sx={{ p: 4, borderRadius: 5, background: 'rgba(255,255,255,0.92)' }}>
        {loading ? (
          <div style={{ textAlign: "center", margin: 40 }}><CircularProgress /></div>
        ) : error ? (
          <Typography color="error" align="center">{error}</Typography>
        ) : (
          <AnimatePresence mode="wait">
            {phase === 'choose' && (
              <motion.div
                key="choose"
                initial={{ opacity: 0, y: 40 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -40 }}
                transition={{ duration: 0.5 }}
              >
                <Typography variant="h5" fontWeight={700} mb={2} align="center" color="primary">
                  {situation}
                </Typography>
                <Typography align="center" mb={2} color="text.secondary">Выберите одну из своих карт:</Typography>
                <Grid container spacing={3} justifyContent="center">
                  {cards.map((card) => (
                    <Grid item xs={12} sm={4} key={card.id}>
                      <motion.div whileHover={{ scale: 1.07 }} whileTap={{ scale: 0.97 }}>
                        <Paper elevation={3} sx={{ p: 2, borderRadius: 4, cursor: 'pointer', background: 'linear-gradient(120deg,#FFD1B3,#F8C8DC,#B3E5FC,#B2F2CC)', transition: 'box-shadow 0.2s', boxShadow: selectedCard === card.id ? '0 0 0 4px #FFB6B9' : undefined }} onClick={() => handleChooseCard(card.id)}>
                          <Typography variant="h6" fontWeight={600} align="center">{card.name}</Typography>
                          {card.image_url && <img src={card.image_url} alt={card.name} style={{ width: '100%', borderRadius: 8, marginTop: 8 }} />}
                        </Paper>
                      </motion.div>
                    </Grid>
                  ))}
                </Grid>
              </motion.div>
            )}
            {phase === 'vote' && (
              <motion.div
                key="vote"
                initial={{ opacity: 0, y: 40 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -40 }}
                transition={{ duration: 0.5 }}
              >
                <Typography variant="h5" fontWeight={700} mb={2} align="center" color="primary">
                  Голосование
                </Typography>
                <Typography align="center" mb={2} color="text.secondary">Выберите лучшую карту (кроме своей):</Typography>
                <Grid container spacing={3} justifyContent="center">
                  {choices.filter(c => c.user_id !== userId).map((choice) => (
                    <Grid item xs={12} sm={4} key={choice.id}>
                      <motion.div whileHover={{ scale: 1.07 }} whileTap={{ scale: 0.97 }}>
                        <Paper elevation={3} sx={{ p: 2, borderRadius: 4, cursor: 'pointer', background: 'linear-gradient(120deg,#FFD1B3,#F8C8DC,#B3E5FC,#B2F2CC)', transition: 'box-shadow 0.2s', boxShadow: votedCard === choice.id ? '0 0 0 4px #B2F2CC' : undefined }} onClick={() => handleVote(choice.id)}>
                          <Typography variant="h6" fontWeight={600} align="center">{choice.card.name}</Typography>
                          {choice.card.image_url && <img src={choice.card.image_url} alt={choice.card.name} style={{ width: '100%', borderRadius: 8, marginTop: 8 }} />}
                          <div style={{ textAlign: 'center', marginTop: 8 }}>
                            <Avatar sx={{ bgcolor: '#B3E5FC', mx: 'auto' }}>{choice.user_id}</Avatar>
                          </div>
                        </Paper>
                      </motion.div>
                    </Grid>
                  ))}
                </Grid>
              </motion.div>
            )}
            {phase === 'results' && results && (
              <motion.div
                key="results"
                initial={{ opacity: 0, y: 40 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -40 }}
                transition={{ duration: 0.5 }}
              >
                <Typography variant="h5" fontWeight={700} mb={2} align="center" color="primary">
                  Результаты раунда
                </Typography>
                <Typography align="center" mb={2} color="text.secondary">Победитель: <b>{results.winner_nickname || '—'}</b></Typography>
                <Grid container spacing={3} justifyContent="center">
                  {results.choices?.map((choice: any) => (
                    <Grid item xs={12} sm={4} key={choice.id}>
                      <Paper elevation={3} sx={{ p: 2, borderRadius: 4, background: 'linear-gradient(120deg,#FFD1B3,#F8C8DC,#B3E5FC,#B2F2CC)', border: results.winner_card_id === choice.card_id ? '2px solid #B2F2CC' : undefined }}>
                        <Typography variant="h6" fontWeight={600} align="center">{choice.card_name}</Typography>
                        {choice.card_image_url && <img src={choice.card_image_url} alt={choice.card_name} style={{ width: '100%', borderRadius: 8, marginTop: 8 }} />}
                        <Typography align="center" color="text.secondary" mt={1}>Игрок: {choice.nickname}</Typography>
                        <Typography align="center" color="text.secondary" mt={1}>Голоса: {choice.votes_count}</Typography>
                      </Paper>
                    </Grid>
                  ))}
                </Grid>
                <Button variant="contained" color="primary" sx={{ mt: 4, width: '100%' }} onClick={onGameEnd}>
                  Следующий раунд / Завершить игру
                </Button>
              </motion.div>
            )}
          </AnimatePresence>
        )}
      </Paper>
    </div>
  );
} 