/**
 * Utility for centralizing logs and sending them to the backend.
 */

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

export class AppLogger {
  private static async sendLog(level: string, message: string, context?: unknown) {
    try {
      const payload = {
        source: 'frontend',
        level,
        message,
        timestamp: new Date().toISOString(),
        context: context || null,
      };

      await fetch(`${API_BASE_URL}/logs`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });
    } catch (e) {
      // Fallback: If we fail to send log, we just log to console (avoid infinite loop)
      console.warn('Failed to send log to backend:', e);
    }
  }

  static info(message: string, context?: unknown) {
    console.info(`[INFO] ${message}`, context ? context : '');
    this.sendLog('INFO', message, context);
  }

  static warn(message: string, context?: unknown) {
    console.warn(`[WARN] ${message}`, context ? context : '');
    this.sendLog('WARN', message, context);
  }

  static error(message: string, context?: unknown) {
    console.error(`[ERROR] ${message}`, context ? context : '');
    this.sendLog('ERROR', message, context);
  }

  static debug(message: string, context?: unknown) {
    console.debug(`[DEBUG] ${message}`, context ? context : '');
    this.sendLog('DEBUG', message, context);
  }
}
