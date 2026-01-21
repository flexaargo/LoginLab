import jwt from 'jsonwebtoken';
import { env } from '../env';
import crypto from 'crypto';
import { z } from 'zod';

const accessTokenSchema = z.object({
  userId: z.string(),
});

export function generateAccessToken(userId: string) {
  const payload = accessTokenSchema.parse({ userId });
  return jwt.sign(payload, env.JWT_SECRET, { expiresIn: '15m' });
}

export function verifyAccessToken(token: string) {
  return accessTokenSchema.parse(jwt.verify(token, env.JWT_SECRET));
}

export function hashRefreshToken(token: string) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function generateRefreshToken() {
  return crypto.randomUUID();
}
