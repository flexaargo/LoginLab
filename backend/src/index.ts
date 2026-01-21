import { Hono } from 'hono';
import authRoutes from './routes/auth';
import { env } from './env';

const app = new Hono();

app.route('/auth', authRoutes);

app.get('/', (c) => c.text('API is running'));

export default {
  port: env.PORT,
  fetch: app.fetch,
};
