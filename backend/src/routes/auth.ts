import { Hono, type Context } from 'hono';
import z from 'zod';
import { db } from '../db';
import { and, eq } from 'drizzle-orm';
import { identities } from '../db/schema';
import { exchangeAppleAuthorizationCode, verifyAppleIdentityToken } from '../utils/apple';
import {
  createSession,
  createUserAndIdentity,
  updateIdentityRefreshToken,
} from '../services/auth.service';

const app = new Hono();

/**
 * Extracts the client IP address from the request.
 * Checks proxy headers first, then falls back to the direct connection IP.
 */
function getClientIp(c: Context): string | undefined {
  // Check proxy headers first (for production behind a reverse proxy)
  const forwardedFor = c.req.header('X-Forwarded-For');
  const forwardedForIp = forwardedFor?.split(',')[0]?.trim();
  if (forwardedForIp) {
    return forwardedForIp;
  }

  const realIp = c.req.header('X-Real-IP');
  if (realIp) {
    return realIp.trim();
  }

  // Fall back to direct connection IP (for local development)
  // In Bun, connection info might be available through the request
  try {
    const rawRequest = c.req.raw;
    // Try different ways Bun might expose connection info
    const remoteAddress =
      (rawRequest as Request & { remoteAddress?: string })?.remoteAddress ||
      (rawRequest as Request & { socket?: { remoteAddress?: string } })?.socket?.remoteAddress ||
      (rawRequest as Request & { conn?: { remoteAddress?: string } })?.conn?.remoteAddress;

    if (remoteAddress && typeof remoteAddress === 'string') {
      // Handle IPv6-mapped IPv4 addresses (::ffff:127.0.0.1 -> 127.0.0.1)
      return remoteAddress.replace(/^::ffff:/, '');
    }
  } catch {
    // Ignore errors accessing remote address
  }

  return undefined;
}

const signInSchema = z.object({
  /// The identity token provided by Apple.
  identityToken: z.string().min(1),
  /// The authorization code provided by Apple.
  authorizationCode: z.string().min(1),
  /// The nonce used for the authentication request.
  nonce: z.string().min(1),
  /// The email of the user.
  email: z.email().optional(),
  /// The full name of the user.
  fullName: z.string().optional(),
});

app.post('/signin', async (c) => {
  try {
    const body = signInSchema.parse(await c.req.json());

    // Verify Apple identity token and exchange authorization code
    const [identityTokenPayload, tokenResponse] = await Promise.all([
      verifyAppleIdentityToken(body.identityToken, body.nonce),
      exchangeAppleAuthorizationCode(body.authorizationCode),
    ]);

    const appleUserId = identityTokenPayload.sub;

    // Find existing identity
    const existingIdentity = await db.query.identities.findFirst({
      where: and(eq(identities.provider, 'apple'), eq(identities.providerUserId, appleUserId)),
      with: { user: true },
    });

    // Handle new user registration
    if (!existingIdentity?.user) {
      if (!body.email || !body.fullName) {
        return c.json({ error: 'Email and full name are required for new users' }, 400);
      }

      const displayName = body.fullName || identityTokenPayload.email?.split('@')[0] || 'Anonymous';
      const { user } = await createUserAndIdentity({
        fullName: body.fullName,
        email: body.email,
        displayName,
        appleUserId,
        appleRefreshToken: tokenResponse.refresh_token,
      });

      const session = await createSession({
        userId: user.id,
        userAgent: c.req.header('User-Agent'),
        deviceName: c.req.header('X-Device-Name'),
        ipAddress: getClientIp(c),
      });
      return c.json({ user, ...session }, 201);
    }

    // Handle existing user sign-in
    await updateIdentityRefreshToken(existingIdentity.id, tokenResponse.refresh_token);

    const session = await createSession({
      userId: existingIdentity.user.id,
      userAgent: c.req.header('User-Agent'),
      deviceName: c.req.header('X-Device-Name'),
      ipAddress: getClientIp(c),
    });

    return c.json({ user: existingIdentity.user, ...session });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return c.json({ error: 'Invalid request body', details: error.issues }, 400);
    }
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.error('Sign-in error:', message);
    return c.json({ error: message }, 500);
  }
});

export default app;
