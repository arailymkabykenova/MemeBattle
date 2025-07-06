import { createTheme } from '@mui/material/styles';

// Основные цвета
const peach = '#FFD1B3';      // Персиковый
const pink = '#F8C8DC';       // Нежно-розовый
const blue = '#B3E5FC';       // Голубой
const mint = '#B2F2CC';       // Нежно-зеленый
const accent = '#FFB6B9';     // Яркий акцент (розово-персиковый)

// Градиенты
export const mainGradient = `linear-gradient(135deg, ${peach} 0%, ${pink} 40%, ${blue} 80%, ${mint} 100%)`;
export const buttonGradient = `linear-gradient(90deg, ${peach} 0%, ${pink} 50%, ${blue} 100%)`;

const theme = createTheme({
  palette: {
    primary: {
      main: accent,
      light: peach,
      dark: pink,
      contrastText: '#fff',
    },
    secondary: {
      main: blue,
      light: mint,
      dark: '#7ec8e3',
      contrastText: '#fff',
    },
    background: {
      default: peach,
      paper: '#fff',
    },
    info: {
      main: blue,
    },
    success: {
      main: mint,
    },
    error: {
      main: accent,
    },
  },
  typography: {
    fontFamily: 'Inter, Roboto, Arial, sans-serif',
    h1: { fontWeight: 700 },
    h2: { fontWeight: 700 },
    h3: { fontWeight: 600 },
    button: { textTransform: 'none', fontWeight: 600 },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          background: buttonGradient,
          color: '#fff',
          borderRadius: 12,
          boxShadow: '0 2px 8px 0 rgba(255,182,185,0.10)',
          transition: 'transform 0.15s',
          '&:hover': {
            transform: 'scale(1.04)',
            background: buttonGradient,
            boxShadow: '0 4px 16px 0 rgba(179,229,252,0.15)',
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          background: '#fff',
          borderRadius: 16,
          boxShadow: '0 2px 16px 0 rgba(248,200,220,0.10)',
        },
      },
    },
  },
});

export default theme; 