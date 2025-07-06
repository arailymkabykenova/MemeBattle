import React from 'react';
import { Box, Container, Typography, Button } from '@mui/material';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';

const LobbyPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #FFB3BA 0%, #4ECDC4 50%, #FF6B6B 100%)',
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
          <Box
            sx={{
              textAlign: 'center',
              p: 4,
              background: 'rgba(255, 255, 255, 0.95)',
              borderRadius: 3,
              backdropFilter: 'blur(10px)',
            }}
          >
            <Typography variant="h3" gutterBottom sx={{ fontWeight: 700 }}>
              🎮 Game Lobby
            </Typography>
            <Typography variant="h6" color="text.secondary" sx={{ mb: 4 }}>
              Waiting for players...
            </Typography>
            <Button
              variant="contained"
              onClick={() => navigate('/home')}
              sx={{
                background: 'linear-gradient(45deg, #FF6B6B, #FF8E8E)',
                '&:hover': {
                  background: 'linear-gradient(45deg, #E55A5A, #FF6B6B)',
                },
              }}
            >
              Back to Home
            </Button>
          </Box>
        </motion.div>
      </Container>
    </Box>
  );
};

export default LobbyPage; 