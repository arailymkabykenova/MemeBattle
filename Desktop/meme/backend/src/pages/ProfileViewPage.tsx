import React, { useEffect, useState } from "react";
import { Paper, Typography, Avatar, Button, CircularProgress, Grid } from "@mui/material";
import { motion } from "framer-motion";
import axios from "axios";

const API_URL = "http://localhost:8000";

interface UserProfile {
  nickname: string;
  birth_date: string;
  gender: string;
}

interface ProfileViewPageProps {
  token: string;
  onLogout: () => void;
}

export default function ProfileViewPage({ token, onLogout }: ProfileViewPageProps) {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetchProfile();
    // eslint-disable-next-line
  }, []);

  const fetchProfile = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await axios.get(`${API_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setProfile(res.data);
    } catch (e: any) {
      setError(e.response?.data?.detail || "Ошибка загрузки профиля");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 500, margin: "60px auto", padding: 24 }}>
      <Paper elevation={4} sx={{ p: 4, borderRadius: 5, background: 'rgba(255,255,255,0.92)' }}>
        <Typography variant="h4" fontWeight={700} mb={3} align="center" color="primary">
          Профиль
        </Typography>
        {loading ? (
          <div style={{ textAlign: "center", margin: 40 }}><CircularProgress /></div>
        ) : error ? (
          <Typography color="error" align="center">{error}</Typography>
        ) : profile && (
          <motion.div initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
            <Grid container spacing={3} justifyContent="center" alignItems="center">
              <Grid item xs={12} style={{ textAlign: 'center' }}>
                <Avatar sx={{ bgcolor: 'primary.main', width: 80, height: 80, fontSize: 40, margin: '0 auto', boxShadow: '0 4px 24px #FFD1B3' }}>
                  {profile.nickname[0]?.toUpperCase()}
                </Avatar>
              </Grid>
              <Grid item xs={12} style={{ textAlign: 'center' }}>
                <Typography variant="h5" fontWeight={700} color="primary">{profile.nickname}</Typography>
                <Typography color="text.secondary" mt={1}>Дата рождения: {profile.birth_date}</Typography>
                <Typography color="text.secondary" mt={1}>Пол: {profile.gender === 'female' ? 'Женский' : 'Мужской'}</Typography>
              </Grid>
              <Grid item xs={12} style={{ textAlign: 'center' }}>
                <Button variant="contained" color="primary" onClick={onLogout} sx={{ mt: 2, px: 6, py: 1.5, fontSize: 18 }}>
                  Выйти
                </Button>
              </Grid>
            </Grid>
          </motion.div>
        )}
      </Paper>
    </div>
  );
} 