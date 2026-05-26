/**
 * Server-side log relay for the Smart Attendance System frontend.
 *
 * Next.js pages and server components cannot call the Python backend directly
 * from the browser in all deployment scenarios. This route acts as a local
 * relay: it receives structured log events from the client-side AppLogger,
 * writes them to logs/frontend.log (via the backend /logs endpoint), and
 * returns immediately.
 *
 * POST /api/log
 * Body: { level, message, context?, timestamp?, user_id?, platform_version? }
 */

import { NextRequest, NextResponse } from 'next/server';
import path from 'path';
import fs from 'fs';

const LOGS_DIR = path.resolve(process.cwd(), '..', 'logs');
const LOG_FILE = path.join(LOGS_DIR, 'frontend.log');

const VALID_LEVELS = new Set(['DEBUG', 'INFO', 'WARN', 'WARNING', 'ERROR', 'CRITICAL']);

function ensureLogDir(): void {
  if (!fs.existsSync(LOGS_DIR)) {
    fs.mkdirSync(LOGS_DIR, { recursive: true });
  }
}

function formatLine(
  level: string,
  message: string,
  timestamp: string,
  userId?: string | null,
  platformVersion?: string,
  context?: unknown,
): string {
  const parts = [`${timestamp} [${level.padEnd(8)}] [frontend] ${message}`];
  if (userId) parts.push(`| user_id=${userId}`);
  if (platformVersion) parts.push(`| platform=${platformVersion}`);
  if (context) parts.push(`| context=${JSON.stringify(context)}`);
  return parts.join(' ');
}

export async function POST(request: NextRequest): Promise<NextResponse> {
  let body: Record<string, unknown>;

  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  const message = typeof body.message === 'string' ? body.message.trim() : '';
  if (!message) {
    return NextResponse.json({ error: 'message is required' }, { status: 400 });
  }

  const rawLevel = typeof body.level === 'string' ? body.level.toUpperCase() : 'INFO';
  const level = VALID_LEVELS.has(rawLevel) ? rawLevel : 'INFO';
  const timestamp = typeof body.timestamp === 'string'
    ? body.timestamp
    : new Date().toISOString();
  const userId = typeof body.user_id === 'string' ? body.user_id : null;
  const platformVersion = typeof body.platform_version === 'string'
    ? body.platform_version
    : undefined;

  const line = formatLine(level, message, timestamp, userId, platformVersion, body.context);

  try {
    ensureLogDir();
    fs.appendFileSync(LOG_FILE, line + '\n', 'utf8');
  } catch (fsErr) {
    // Log file write failures must never surface to the client
    console.error('[log-relay] Failed to write to log file:', fsErr);
  }

  return NextResponse.json({ status: 'ok' });
}
