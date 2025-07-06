import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import { ThemeProvider, CssBaseline } from '@mui/material';
import theme, { mainGradient } from './theme';

const root = document.getElementById('root');

if (root) {
  ReactDOM.createRoot(root).render(
    <React.StrictMode>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <div style={{ minHeight: '100vh', minWidth: '100vw', background: mainGradient, transition: 'background 0.8s', position: 'fixed', inset: 0, zIndex: -1 }} />
        <App />
      </ThemeProvider>
    </React.StrictMode>
  );
} 