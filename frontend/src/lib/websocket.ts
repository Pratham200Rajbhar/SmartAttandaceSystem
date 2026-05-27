"use client";

import { useAuthStore } from "@/store/authStore";

type MessageHandler = (data: Record<string, unknown>) => void;

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

class WebSocketClient {
  private ws: WebSocket | null = null;
  private handlers = new Map<string, Set<MessageHandler>>();
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private pingTimer: ReturnType<typeof setInterval> | null = null;

  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) return;

    const token = useAuthStore.getState().token;
    if (!token) return;

    const wsUrl = API_BASE_URL.replace("http://", "ws://").replace("https://", "wss://");
    const socket = new WebSocket(`${wsUrl}/ws/connect`);
    this.ws = socket;

    socket.onopen = () => {
      if (this.ws !== socket) {
        socket.close();
        return;
      }
      if (socket.readyState === WebSocket.OPEN) {
        socket.send(JSON.stringify({ type: "auth", token }));
        this.reconnectAttempts = 0;
        this.startPing();
      }
    };

    socket.onmessage = (event) => {
      if (this.ws !== socket) return;
      try {
        const data = JSON.parse(event.data) as Record<string, unknown>;
        if (data.type === "pong") return;
        const typeHandlers = this.handlers.get(String(data.type));
        typeHandlers?.forEach((handler) => handler(data));
      } catch {
        // ignore parse errors
      }
    };

    socket.onclose = () => {
      if (this.ws !== socket) return;
      this.stopPing();
      this.scheduleReconnect();
    };

    socket.onerror = () => {
      socket.close();
    };
  }

  on(type: string, handler: MessageHandler): () => void {
    if (!this.handlers.has(type)) {
      this.handlers.set(type, new Set());
    }
    this.handlers.get(type)!.add(handler);
    return () => this.handlers.get(type)?.delete(handler);
  }

  disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }
    this.stopPing();
    this.ws?.close();
    this.ws = null;
    this.reconnectAttempts = 0;
  }

  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) return;
    this.reconnectAttempts++;
    this.reconnectTimer = setTimeout(() => this.connect(), 3000 * this.reconnectAttempts);
  }

  private startPing(): void {
    this.pingTimer = setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: "ping" }));
      }
    }, 30000);
  }

  private stopPing(): void {
    if (this.pingTimer) clearInterval(this.pingTimer);
    this.pingTimer = null;
  }
}

let instance: WebSocketClient | null = null;

export function getWebSocket(): WebSocketClient {
  if (!instance) {
    instance = new WebSocketClient();
  }
  return instance;
}
