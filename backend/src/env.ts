import 'dotenv/config';
import z from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.number().default(3000),
  DATABASE_URL: z.url(),
  APPLE_CLIENT_ID: z.string(),
  APPLE_CLIENT_SECRET: z.string(),
  JWT_SECRET: z.string(),
});

export const env = envSchema.parse(process.env);
