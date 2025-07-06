import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Avatar,
  Chip,
} from '@mui/material';
import { motion } from 'framer-motion';
import { useAuth } from '../contexts/AuthContext';

const HomePage: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const menuItems = [
    {
      title: 'Find Game',
      description: 'Join public rooms or create your own',
      icon: '🎮',
      path: '/rooms',
      color: '#FF6B6B',
    },
    {
      title: 'My Cards',
      description: 'View your meme card collection',
      icon: '🃏',
      path: '/cards',
      color: '#4ECDC4',
    },
    {
      title: 'Profile',
      description: 'View and edit your profile',
      icon: '👤',
      path: '/profile',
      color: '#FFB3BA',
    },
  ];

  const handleLogout = () => {
    logout();
    navigate('/auth');
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #FF6B6B 0%, #FFB3BA 50%, #4ECDC4 100%)',
        padding: 2,
      }}
    >
      <Container maxWidth="lg">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
        >
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              mb: 4,
              p: 3,
              background: 'rgba(255, 255, 255, 0.95)',
              borderRadius: 3,
              backdropFilter: 'blur(10px)',
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Avatar
                sx={{
                  bgcolor: '#FF6B6B',
                  width: 56,
                  height: 56,
                  fontSize: '1.5rem',
                }}
              >
                {user?.nickname?.charAt(0) || 'U'}
              </Avatar>
              <Box>
                <Typography variant="h5" fontWeight={600}>
                  Welcome, {user?.nickname || 'Player'}!
                </Typography>
                <Chip
                  label={`Rating: ${user?.rating || 0}`}
                  color="primary"
                  size="small"
                />
              </Box>
            </Box>
            <Button
              variant="outlined"
              onClick={handleLogout}
              sx={{
                borderColor: '#FF6B6B',
                color: '#FF6B6B',
                '&:hover': {
                  borderColor: '#E55A5A',
                  backgroundColor: 'rgba(255, 107, 107, 0.04)',
                },
              }}
            >
              Logout
            </Button>
          </Box>
        </motion.div>

        {/* Menu Grid */}
        <Grid container spacing={3}>
          {menuItems.map((item, index) => (
            <Grid item xs={12} sm={6} md={4} key={item.title}>
              <motion.div
                initial={{ opacity: 0, y: 50 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Card
                  sx={{
                    height: '100%',
                    cursor: 'pointer',
                    background: 'rgba(255, 255, 255, 0.95)',
                    backdropFilter: 'blur(10px)',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      boxShadow: '0 8px 32px rgba(0, 0, 0, 0.12)',
                    },
                  }}
                  onClick={() => navigate(item.path)}
                >
                  <CardContent
                    sx={{
                      textAlign: 'center',
                      p: 4,
                    }}
                  >
                    <Typography
                      variant="h1"
                      sx={{
                        fontSize: '4rem',
                        mb: 2,
                        filter: 'drop-shadow(0 4px 8px rgba(0,0,0,0.1))',
                      }}
                    >
                      {item.icon}
                    </Typography>
                    <Typography
                      variant="h5"
                      component="h2"
                      gutterBottom
                      sx={{
                        fontWeight: 600,
                        color: item.color,
                        mb: 2,
                      }}
                    >
                      {item.title}
                    </Typography>
                    <Typography
                      variant="body1"
                      color="text.secondary"
                      sx={{ mb: 3 }}
                    >
                      {item.description}
                    </Typography>
                    <Button
                      variant="contained"
                      fullWidth
                      sx={{
                        background: `linear-gradient(45deg, ${item.color}, ${item.color}dd)`,
                        '&:hover': {
                          background: `linear-gradient(45deg, ${item.color}dd, ${item.color})`,
                        },
                      }}
                    >
                      Go to {item.title}
                    </Button>
                  </CardContent>
                </Card>
              </motion.div>
            </Grid>
          ))}
        </Grid>

        {/* Quick Stats */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
        >
          <Box
            sx={{
              mt: 4,
              p: 3,
              background: 'rgba(255, 255, 255, 0.95)',
              borderRadius: 3,
              backdropFilter: 'blur(10px)',
            }}
          >
            <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
              Quick Stats
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={6} sm={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="primary" fontWeight={700}>
                    {user?.rating || 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Rating
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="secondary" fontWeight={700}>
                    0
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Games Won
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="success.main" fontWeight={700}>
                    0
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Cards Collected
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Box textAlign="center">
                  <Typography variant="h4" color="info.main" fontWeight={700}>
                    0
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Games Played
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          </Box>
        </motion.div>
      </Container>
    </Box>
  );
};

export default HomePage; 