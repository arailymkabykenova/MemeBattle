import { useEffect, useRef } from 'react';

export function useWebSocket(url: string, onMessage: (msg: any) => void) {
  const ws = useRef<WebSocket | null>(null);

  useEffect(() => {
    ws.current = new WebSocket(url);
    ws.current.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        onMessage(data);
      } catch (e) {
        // ignore parse errors
      }
    };
    ws.current.onclose = () => {
      // Автоматическое переподключение через 2 секунды
      setTimeout(() => {
        ws.current = new WebSocket(url);
        ws.current.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data);
            onMessage(data);
          } catch (e) {}
        };
      }, 2000);
    };
    return () => {
      ws.current?.close();
    };
    // eslint-disable-next-line
  }, [url]);
} 