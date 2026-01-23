import jwt from 'jsonwebtoken';
import { env } from '../env';
import crypto from 'crypto';
import { z } from 'zod';

const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;

const REFRESH_TOKEN_BYTES = 32;
const REFRESH_TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60; // 30 days

const accessTokenSchema = z.object({
  userId: z.string(),
});

export function generateAccessToken(userId: string) {
  const payload = accessTokenSchema.parse({ userId });
  const expiresAt = Math.floor(Date.now() / 1000) + ACCESS_TOKEN_TTL_SECONDS;
  const accessToken = jwt.sign(
    {
      ...payload,
      exp: expiresAt,
    },
    env.JWT_SECRET,
  );
  return { accessToken, expiresAt };
}

export function verifyAccessToken(token: string) {
  return accessTokenSchema.parse(jwt.verify(token, env.JWT_SECRET));
}

export function hashRefreshToken(token: string) {
  return crypto.createHmac('sha256', env.REFRESH_TOKEN_PEPPER).update(token).digest('hex');
}

export function generateRefreshToken() {
  const expiresAt = Math.floor(Date.now() / 1000) + REFRESH_TOKEN_TTL_SECONDS;
  const refreshToken = crypto.randomBytes(REFRESH_TOKEN_BYTES).toString('base64url');
  return { refreshToken, expiresAt };
}
