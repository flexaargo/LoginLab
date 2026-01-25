import { createMiddleware } from 'hono/factory';
import { verifyAccessToken } from '../utils/tokens';

export const authMiddleware = createMiddleware<{ Variables: { userId: string } }>(
  async (c, next) => {
    const token = c.req
      .header('Authorization')
      ?.replace(/^Bearer\s+/i, '')
      ?.trim();
    if (!token) return c.json({ error: 'Unauthorized' }, 401);
    try {
      const decoded = verifyAccessToken(token);
      c.set('userId', decoded.userId);
    } catch {
      return c.json({ error: 'Invalid or expired token' }, 401);
    }
    await next();
  },
);
