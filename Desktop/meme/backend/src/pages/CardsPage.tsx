import React, { useEffect, useState } from "react";
import { Paper, Typography, Grid, Tabs, Tab, CircularProgress } from "@mui/material";
import { motion, AnimatePresence } from "framer-motion";
import axios from "axios";

const API_URL = "http://localhost:8000";

interface Card {
  id: number;
  name: string;
  image_url?: string;
  type: string;
}

type CardType = 'starter' | 'standard' | 'unique';

interface CardsPageProps {
  token: string;
}

const typeLabels: Record<CardType, string> = {
  starter: 'Стартовые',
  standard: 'Обычные',
  unique: 'Уникальные',
};

export default function CardsPage({ token }: CardsPageProps) {
  const [cards, setCards] = useState<Record<CardType, Card[]>>({ starter: [], standard: [], unique: [] });
  const [tab, setTab] = useState<CardType>('starter');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetchCards();
    // eslint-disable-next-line
  }, []);

  const fetchCards = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await axios.get(`${API_URL}/cards/my-cards`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCards({
        starter: res.data.starter || [],
        standard: res.data.standard || [],
        unique: res.data.unique || [],
      });
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка загрузки карт");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 900, margin: "40px auto", padding: 24 }}>
      <Paper elevation={4} sx={{ p: 4, borderRadius: 5, background: 'rgba(255,255,255,0.92)' }}>
        <Typography variant="h4" fontWeight={700} mb={3} align="center" color="primary">
          Моя коллекция карт
        </Typography>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} centered sx={{ mb: 3 }}>
          <Tab label="Стартовые" value="starter" />
          <Tab label="Обычные" value="standard" />
          <Tab label="Уникальные" value="unique" />
        </Tabs>
        {loading ? (
          <div style={{ textAlign: "center", margin: 40 }}><CircularProgress /></div>
        ) : error ? (
          <Typography color="error" align="center">{error}</Typography>
        ) : (
          <AnimatePresence mode="wait">
            <motion.div
              key={tab}
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -40 }}
              transition={{ duration: 0.5 }}
            >
              <Grid container spacing={3} justifyContent="center">
                {cards[tab].length === 0 ? (
                  <Grid item xs={12}>
                    <Typography align="center" color="text.secondary">Нет карт этого типа</Typography>
                  </Grid>
                ) : (
                  cards[tab].map((card) => (
                    <Grid item xs={12} sm={6} md={4} key={card.id}>
                      <motion.div whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.98 }}>
                        <Paper elevation={3} sx={{ p: 2, borderRadius: 4, background: 'linear-gradient(120deg,#FFD1B3,#F8C8DC,#B3E5FC,#B2F2CC)' }}>
                          <Typography variant="h6" fontWeight={600} align="center">{card.name}</Typography>
                          {card.image_url && <img src={card.image_url} alt={card.name} style={{ width: '100%', borderRadius: 8, marginTop: 8 }} />}
                          <Typography align="center" color="text.secondary" mt={1}>{typeLabels[card.type as CardType] || card.type}</Typography>
                        </Paper>
                      </motion.div>
                    </Grid>
                  ))
                )}
              </Grid>
            </motion.div>
          </AnimatePresence>
        )}
      </Paper>
    </div>
  );
} 