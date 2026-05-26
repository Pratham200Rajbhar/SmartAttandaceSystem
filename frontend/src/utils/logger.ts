/**
 * Unified frontend logger for the Smart Attendance System.
 *
 * Every log call:
 *  1. Writes to the browser console for local development visibility.
 *  2. Ships the event to the backend /api/v1/logs endpoint so it lands in
 *     logs/frontend.log on the server.
 *
 * Log events are batched for 500 ms and sent in a single request to avoid
 * flooding the backend when many events fire in rapid succession (e.g. React
 * renders in strict mode).
 */

type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL';

interface LogPayload {
  source: 'frontend';
  level: LogLevel;
  message: string;
  timestamp: string;
  context?: unknown;
  user_id?: string | null;
  platform_version?: string;
}

// Read the base URL once at module load time to avoid repeated env lookups.
const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

// App version sourced from the environment (set via next.config.ts if needed).
const APP_VERSION =
  process.env.NEXT_PUBLIC_APP_VERSION || 'unknown';

// ---------------------------------------------------------------------------
// Batching queue — events accumulate for BATCH_DELAY_MS then flush together
// ---------------------------------------------------------------------------
const BATCH_DELAY_MS = 500;
let _queue: LogPayload[] = [];
let _batchTimer: ReturnType<typeof setTimeout> | null = null;

function _scheduleFlush(): void {
  if (_batchTimer !== null) return;
  _batchTimer = setTimeout(() => {
    _batchTimer = null;
    _flush();
  }, BATCH_DELAY_MS);
}

async function _flush(): Promise<void> {
  if (_queue.length === 0) return;
  const batch = _queue.splice(0, _queue.length);

  for (const payload of batch) {
    try {
      await fetch(`${API_BASE_URL}/logs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        // Keep-alive ensures the request completes even during page unload
        keepalive: true,
      });
    } catch {
      // Silently swallow — we must never let logger failures affect the UI
    }
  }
}

// ---------------------------------------------------------------------------
// Resolve the current user ID from localStorage (set by the auth store)
// ---------------------------------------------------------------------------
function _resolveUserId(): string | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = localStorage.getItem('auth_user');
    if (!raw) return null;
    const parsed = JSON.parse(raw) as { id?: string };
    return parsed?.id ?? null;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Core send helper
// ---------------------------------------------------------------------------
function _enqueue(level: LogLevel, message: string, context?: unknown): void {
  // Never send logs during test runs
  if (process.env.NODE_ENV === 'test') return;

  const payload: LogPayload = {
    source: 'frontend',
    level,
    message,
    timestamp: new Date().toISOString(),
    platform_version: APP_VERSION,
    user_id: _resolveUserId(),
    ...(context !== undefined && context !== null ? { context } : {}),
  };

  _queue.push(payload);
  _scheduleFlush();
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
export const AppLogger = {
  /** Fine-grained diagnostic information — not written in production unless DEBUG mode is on. */
  debug(message: string, context?: unknown): void {
    if (process.env.NODE_ENV === 'development') {
      // eslint-disable-next-line no-console
      console.debug(`[DEBUG] ${message}`, context ?? '');
    }
    _enqueue('DEBUG', message, context);
  },

  /** Routine operational events — page views, successful API calls, etc. */
  info(message: string, context?: unknown): void {
    // eslint-disable-next-line no-console
    console.info(`[INFO] ${message}`, context ?? '');
    _enqueue('INFO', message, context);
  },

  /** Non-fatal issues that the system can recover from. */
  warn(message: string, context?: unknown): void {
    // eslint-disable-next-line no-console
    console.warn(`[WARN] ${message}`, context ?? '');
    _enqueue('WARN', message, context);
  },

  /** Errors that affect user-visible functionality. */
  error(message: string, context?: unknown): void {
    // eslint-disable-next-line no-console
    console.error(`[ERROR] ${message}`, context ?? '');
    _enqueue('ERROR', message, context);
  },

  /** Severe errors — unhandled exceptions, application crashes. */
  critical(message: string, context?: unknown): void {
    // eslint-disable-next-line no-console
    console.error(`[CRITICAL] ${message}`, context ?? '');
    _enqueue('CRITICAL', message, context);
  },
};
