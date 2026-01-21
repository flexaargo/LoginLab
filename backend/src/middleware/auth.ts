import type { Context, Next } from 'hono';
import { verifyAccessToken } from '../utils/tokens';

export async function authMiddleware(c: Context, next: Next) {
  const token = c.req.header('Authorization')?.replace('Bearer ', '');
  if (!token) return c.json({ error: 'Unauthorized' }, 401);

  const decoded = verifyAccessToken(token);
  if (!decoded) return c.json({ error: 'Invalid or expired token' }, 401);

  c.set('userId', decoded.userId);

  await next();
}
