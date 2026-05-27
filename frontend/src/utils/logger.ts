type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const PREFIX: Record<LogLevel, string> = {
  debug: '⚫',
  info: '🔵',
  warn: '🟡',
  error: '🔴',
};

export const logger = {
  debug(message: string, ...args: unknown[]) {
    if (process.env.NODE_ENV === 'development') {
      console.debug(`${PREFIX.debug} ${message}`, ...args);
    }
  },
  info(message: string, ...args: unknown[]) {
    if (process.env.NODE_ENV === 'development') {
      console.info(`${PREFIX.info} ${message}`, ...args);
    }
  },
  warn(message: string, ...args: unknown[]) {
    console.warn(`${PREFIX.warn} ${message}`, ...args);
  },
  error(message: string, ...args: unknown[]) {
    console.error(`${PREFIX.error} ${message}`, ...args);
  },
};
