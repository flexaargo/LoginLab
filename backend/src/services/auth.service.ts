import { db } from '../db';
import { eq } from 'drizzle-orm';
import { identities, sessions, users } from '../db/schema';
import { generateAccessToken, generateRefreshToken, hashRefreshToken } from '../utils/tokens';

interface CreateUserAndIdentityOptions {
  fullName: string;
  email: string;
  displayName: string;
  appleUserId: string;
  appleRefreshToken: string;
}

/**
 * Creates a new user and associated Apple identity in a transaction.
 */
export async function createUserAndIdentity(options: CreateUserAndIdentityOptions) {
  const { fullName, email, displayName, appleUserId, appleRefreshToken } = options;
  return db.transaction(async (tx) => {
    const [user] = await tx
      .insert(users)
      .values({
        fullName,
        email,
        displayName,
      })
      .returning();
    if (!user) throw new Error('Failed to create user');

    const [identity] = await tx
      .insert(identities)
      .values({
        userId: user.id,
        provider: 'apple',
        providerUserId: appleUserId,
        identifier: email.toLowerCase(),
        providerRefreshTokenEnc: appleRefreshToken,
        providerRefreshTokenUpdatedAt: new Date(),
      })
      .returning();
    if (!identity) throw new Error('Failed to create identity');
    return { user, identity };
  });
}

/**
 * Updates the refresh token for an existing identity.
 */
export async function updateIdentityRefreshToken(identityId: string, refreshToken: string) {
  await db
    .update(identities)
    .set({
      providerRefreshTokenEnc: refreshToken,
      providerRefreshTokenUpdatedAt: new Date(),
      updatedAt: new Date(),
    })
    .where(eq(identities.id, identityId));
}

interface CreateSessionOptions {
  userId: string;
  userAgent?: string;
  deviceName?: string;
  ipAddress?: string;
}

interface Session {
  /** The access token for the session. */
  accessToken: string;
  /** Expiration timestamp in seconds since epoch. */
  accessTokenExpiresAt: number;
  /** The refresh token for the session. */
  refreshToken: string;
  /** Expiration timestamp in seconds since epoch. */
  refreshTokenExpiresAt: number;
}

/**
 * Creates a new session for a user and returns access/refresh tokens.
 */
export async function createSession(options: CreateSessionOptions): Promise<Session> {
  const { userId, userAgent, deviceName, ipAddress } = options;
  const { accessToken, expiresAt: accessTokenExpiresAt } = generateAccessToken(userId);
  const { refreshToken, expiresAt: refreshTokenExpiresAt } = generateRefreshToken();
  const refreshTokenHash = hashRefreshToken(refreshToken);

  await db.insert(sessions).values({
    userId,
    refreshTokenHash,
    refreshTokenExpiresAt: new Date(refreshTokenExpiresAt * 1000),
    userAgent,
    deviceName,
    ipAddress,
  });

  return { accessToken, accessTokenExpiresAt, refreshToken, refreshTokenExpiresAt };
}
