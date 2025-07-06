import React from 'react';
import { Box, Container, Typography, Button } from '@mui/material';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';

const GamePage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #4ECDC4 0%, #FF6B6B 50%, #FFB3BA 100%)',
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
              🃏 Game in Progress
            </Typography>
            <Typography variant="h6" color="text.secondary" sx={{ mb: 4 }}>
              Playing meme cards...
            </Typography>
            <Button
              variant="contained"
              onClick={() => navigate('/home')}
              sx={{
                background: 'linear-gradient(45deg, #4ECDC4, #45B7AA)',
                '&:hover': {
                  background: 'linear-gradient(45deg, #45B7AA, #3DA89A)',
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

export default GamePage; 