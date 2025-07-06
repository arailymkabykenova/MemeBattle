import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
} from '@mui/material';
import { motion } from 'framer-motion';
import { useAuth } from '../contexts/AuthContext';

const AuthPage: React.FC = () => {
  const [deviceId, setDeviceId] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const generateDeviceId = () => {
    const id = 'device_' + Math.random().toString(36).substr(2, 9);
    setDeviceId(id);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!deviceId.trim()) {
      setError('Please enter a device ID');
      return;
    }

    setIsLoading(true);
    setError('');

    try {
      await login(deviceId);
      navigate('/profile');
    } catch (err) {
      setError('Authentication failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #FF6B6B 0%, #FFB3BA 50%, #4ECDC4 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 2,
      }}
    >
      <Container maxWidth="sm">
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <Paper
            elevation={8}
            sx={{
              padding: 4,
              borderRadius: 3,
              background: 'rgba(255, 255, 255, 0.95)',
              backdropFilter: 'blur(10px)',
            }}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2, duration: 0.5 }}
            >
              <Typography
                variant="h3"
                component="h1"
                align="center"
                gutterBottom
                sx={{
                  fontWeight: 700,
                  background: 'linear-gradient(45deg, #FF6B6B, #4ECDC4)',
                  backgroundClip: 'text',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  mb: 3,
                }}
              >
                Meme Game
              </Typography>

              <Typography
                variant="h6"
                align="center"
                color="text.secondary"
                sx={{ mb: 4 }}
              >
                Enter your device ID to start playing
              </Typography>

              <form onSubmit={handleSubmit}>
                <TextField
                  fullWidth
                  label="Device ID"
                  value={deviceId}
                  onChange={(e) => setDeviceId(e.target.value)}
                  variant="outlined"
                  sx={{ mb: 2 }}
                  placeholder="Enter or generate device ID"
                />

                <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
                  <Button
                    fullWidth
                    variant="outlined"
                    onClick={generateDeviceId}
                    disabled={isLoading}
                    sx={{
                      borderColor: '#4ECDC4',
                      color: '#4ECDC4',
                      '&:hover': {
                        borderColor: '#45B7AA',
                        backgroundColor: 'rgba(78, 205, 196, 0.04)',
                      },
                    }}
                  >
                    Generate ID
                  </Button>
                </Box>

                {error && (
                  <Alert severity="error" sx={{ mb: 2 }}>
                    {error}
                  </Alert>
                )}

                <Button
                  fullWidth
                  type="submit"
                  variant="contained"
                  disabled={isLoading || !deviceId.trim()}
                  sx={{
                    py: 1.5,
                    background: 'linear-gradient(45deg, #FF6B6B, #FF8E8E)',
                    '&:hover': {
                      background: 'linear-gradient(45deg, #E55A5A, #FF6B6B)',
                    },
                    '&:disabled': {
                      background: '#ccc',
                    },
                  }}
                >
                  {isLoading ? (
                    <CircularProgress size={24} color="inherit" />
                  ) : (
                    'Start Playing'
                  )}
                </Button>
              </form>

              <Typography
                variant="body2"
                align="center"
                color="text.secondary"
                sx={{ mt: 3 }}
              >
                Don't have a device ID? Generate one above!
              </Typography>
            </motion.div>
          </Paper>
        </motion.div>
      </Container>
    </Box>
  );
};

export default AuthPage; 