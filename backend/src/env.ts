import 'dotenv/config';
import z from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.number().default(3000),
  DATABASE_URL: z.url(),
  APPLE_CLIENT_ID: z.string(),
  APPLE_CLIENT_SECRET: z.string(),
  JWT_SECRET: z.string(),
  REFRESH_TOKEN_PEPPER: z.string(),
  S3_BUCKET: z.string().min(1),
  S3_REGION: z.string().min(1),
  S3_ACCESS_KEY_ID: z.string().min(1),
  S3_SECRET_ACCESS_KEY: z.string().min(1),
  S3_ENDPOINT: z.url().optional(),
  S3_SIGNED_URL_EXPIRES_SECONDS: z.coerce.number().int().min(60).max(604800).default(86400),
});

export const env = envSchema.parse(process.env);
