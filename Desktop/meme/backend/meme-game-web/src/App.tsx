import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { AnimatePresence } from 'framer-motion';

// Pages
import AuthPage from './pages/AuthPage';
import ProfilePage from './pages/ProfilePage';
import HomePage from './pages/HomePage';
import RoomsPage from './pages/RoomsPage';
import LobbyPage from './pages/LobbyPage';
import GamePage from './pages/GamePage';
import CardsPage from './pages/CardsPage';
import ProfileViewPage from './pages/ProfileViewPage';

// Context
import { AuthProvider } from './contexts/AuthContext';

// Custom theme with our color palette
const theme = createTheme({
  palette: {
    primary: {
      main: '#FF6B6B', // Peach
      light: '#FF8E8E',
      dark: '#E55A5A',
    },
    secondary: {
      main: '#FFB3BA', // Soft Pink
      light: '#FFC4CA',
      dark: '#E5A1A8',
    },
    background: {
      default: '#F8F9FF',
      paper: '#FFFFFF',
    },
    text: {
      primary: '#2C3E50',
      secondary: '#7F8C8D',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontWeight: 700,
      fontSize: '2.5rem',
    },
    h2: {
      fontWeight: 600,
      fontSize: '2rem',
    },
    h3: {
      fontWeight: 600,
      fontSize: '1.5rem',
    },
    body1: {
      fontSize: '1rem',
      lineHeight: 1.6,
    },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          borderRadius: 12,
          padding: '12px 24px',
          fontWeight: 600,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)',
        },
      },
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <Router>
          <AnimatePresence mode="wait">
            <Routes>
              <Route path="/auth" element={<AuthPage />} />
              <Route path="/profile" element={<ProfilePage />} />
              <Route path="/home" element={<HomePage />} />
              <Route path="/rooms" element={<RoomsPage />} />
              <Route path="/lobby/:roomId" element={<LobbyPage />} />
              <Route path="/game/:roomId" element={<GamePage />} />
              <Route path="/cards" element={<CardsPage />} />
              <Route path="/profile/:userId" element={<ProfileViewPage />} />
              <Route path="/" element={<Navigate to="/auth" replace />} />
            </Routes>
          </AnimatePresence>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
