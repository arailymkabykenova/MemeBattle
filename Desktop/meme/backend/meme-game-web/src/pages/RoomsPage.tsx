import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Button,
  Card,
  CardContent,
  Grid,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import { motion } from 'framer-motion';
import { Add as AddIcon, Refresh as RefreshIcon } from '@mui/icons-material';

interface Room {
  id: string;
  name: string;
  creator: {
    nickname: string;
  };
  current_players: number;
  max_players: number;
  status: 'waiting' | 'playing' | 'finished';
  is_private: boolean;
  created_at: string;
}

const RoomsPage: React.FC = () => {
  const navigate = useNavigate();
  const [rooms, setRooms] = useState<Room[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [newRoomData, setNewRoomData] = useState({
    name: '',
    max_players: 6,
    is_private: false,
  });

  useEffect(() => {
    fetchRooms();
  }, []);

  const fetchRooms = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch('http://localhost:8000/api/rooms', {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });
      
      if (response.ok) {
        const data = await response.json();
        setRooms(data.rooms || []);
      }
    } catch (error) {
      console.error('Failed to fetch rooms:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const createRoom = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch('http://localhost:8000/api/rooms', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(newRoomData),
      });

      if (response.ok) {
        const room = await response.json();
        setCreateDialogOpen(false);
        navigate(`/lobby/${room.id}`);
      }
    } catch (error) {
      console.error('Failed to create room:', error);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'waiting': return 'success';
      case 'playing': return 'warning';
      case 'finished': return 'error';
      default: return 'default';
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #4ECDC4 0%, #FFB3BA 50%, #FF6B6B 100%)',
        padding: 2,
      }}
    >
      <Container maxWidth="lg">
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
            <Typography variant="h4" fontWeight={700}>
              Game Rooms
            </Typography>
            <Box sx={{ display: 'flex', gap: 2 }}>
              <IconButton onClick={fetchRooms} disabled={isLoading}>
                <RefreshIcon />
              </IconButton>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setCreateDialogOpen(true)}
                sx={{
                  background: 'linear-gradient(45deg, #4ECDC4, #45B7AA)',
                  '&:hover': {
                    background: 'linear-gradient(45deg, #45B7AA, #3DA89A)',
                  },
                }}
              >
                Create Room
              </Button>
            </Box>
          </Box>
        </motion.div>

        <Grid container spacing={3}>
          {rooms.map((room, index) => (
            <Grid item xs={12} sm={6} md={4} key={room.id}>
              <motion.div
                initial={{ opacity: 0, y: 50 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                whileHover={{ scale: 1.02 }}
              >
                <Card
                  sx={{
                    cursor: 'pointer',
                    background: 'rgba(255, 255, 255, 0.95)',
                    backdropFilter: 'blur(10px)',
                    transition: 'all 0.3s ease',
                    '&:hover': {
                      boxShadow: '0 8px 32px rgba(0, 0, 0, 0.12)',
                    },
                  }}
                  onClick={() => navigate(`/lobby/${room.id}`)}
                >
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                      <Typography variant="h6" fontWeight={600}>
                        {room.name}
                      </Typography>
                      <Chip
                        label={room.status}
                        color={getStatusColor(room.status) as any}
                        size="small"
                      />
                    </Box>
                    
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                      Created by {room.creator.nickname}
                    </Typography>
                    
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <Typography variant="body2">
                        Players: {room.current_players}/{room.max_players}
                      </Typography>
                      {room.is_private && (
                        <Chip label="Private" size="small" variant="outlined" />
                      )}
                    </Box>
                  </CardContent>
                </Card>
              </motion.div>
            </Grid>
          ))}
        </Grid>

        {rooms.length === 0 && !isLoading && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3 }}
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
              <Typography variant="h6" color="text.secondary">
                No rooms available. Create one to get started!
              </Typography>
            </Box>
          </motion.div>
        )}
      </Container>

      {/* Create Room Dialog */}
      <Dialog open={createDialogOpen} onClose={() => setCreateDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New Room</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Room Name"
            value={newRoomData.name}
            onChange={(e) => setNewRoomData({ ...newRoomData, name: e.target.value })}
            sx={{ mb: 3, mt: 1 }}
          />
          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>Max Players</InputLabel>
            <Select
              value={newRoomData.max_players}
              label="Max Players"
              onChange={(e) => setNewRoomData({ ...newRoomData, max_players: e.target.value as number })}
            >
              <MenuItem value={3}>3 Players</MenuItem>
              <MenuItem value={4}>4 Players</MenuItem>
              <MenuItem value={5}>5 Players</MenuItem>
              <MenuItem value={6}>6 Players</MenuItem>
              <MenuItem value={7}>7 Players</MenuItem>
              <MenuItem value={8}>8 Players</MenuItem>
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={createRoom}
            variant="contained"
            disabled={!newRoomData.name.trim()}
          >
            Create Room
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default RoomsPage; 