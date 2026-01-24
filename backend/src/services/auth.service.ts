import { db } from '../db';
import { and, eq, isNull } from 'drizzle-orm';
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

interface RefreshSessionOptions {
  refreshToken: string;
  userAgent?: string;
  deviceName?: string;
  ipAddress?: string;
}

interface RefreshSessionResult {
  session: Session;
  userId: string;
}

/**
 * Refreshes a session using a valid refresh token.
 * Implements token rotation: the old session is revoked and a new one is created.
 */
export async function refreshSession(
  options: RefreshSessionOptions,
): Promise<RefreshSessionResult> {
  const { refreshToken, userAgent, deviceName, ipAddress } = options;
  const refreshTokenHash = hashRefreshToken(refreshToken);

  // Find the session by refresh token hash
  const existingSession = await db.query.sessions.findFirst({
    where: and(eq(sessions.refreshTokenHash, refreshTokenHash), isNull(sessions.revokedAt)),
    with: { user: true },
  });

  if (!existingSession) {
    throw new Error('Invalid refresh token');
  }

  // Check if the session is expired
  if (existingSession.refreshTokenExpiresAt < new Date()) {
    // Revoke the expired session
    await db
      .update(sessions)
      .set({
        revokedAt: new Date(),
        revokeReason: 'expired',
      })
      .where(eq(sessions.id, existingSession.id));
    throw new Error('Refresh token expired');
  }

  // Generate new tokens
  const { accessToken, expiresAt: accessTokenExpiresAt } = generateAccessToken(
    existingSession.userId,
  );
  const { refreshToken: newRefreshToken, expiresAt: refreshTokenExpiresAt } =
    generateRefreshToken();
  const newRefreshTokenHash = hashRefreshToken(newRefreshToken);

  // Perform token rotation in a transaction
  await db.transaction(async (tx) => {
    // Create the new session
    const [newSession] = await tx
      .insert(sessions)
      .values({
        userId: existingSession.userId,
        refreshTokenHash: newRefreshTokenHash,
        refreshTokenExpiresAt: new Date(refreshTokenExpiresAt * 1000),
        userAgent,
        deviceName,
        ipAddress,
      })
      .returning();

    if (!newSession) {
      throw new Error('Failed to create new session');
    }

    // Revoke the old session and link to the new one
    await tx
      .update(sessions)
      .set({
        revokedAt: new Date(),
        revokeReason: 'rotated',
        replacedBySessionId: newSession.id,
        lastUsedAt: new Date(),
      })
      .where(eq(sessions.id, existingSession.id));
  });

  return {
    session: {
      accessToken,
      accessTokenExpiresAt,
      refreshToken: newRefreshToken,
      refreshTokenExpiresAt,
    },
    userId: existingSession.userId,
  };
}

/**
 * Revokes a session by its refresh token.
 * Returns true if a session was revoked, false if the token was not found or already revoked.
 */
export async function revokeSession(refreshToken: string): Promise<boolean> {
  const refreshTokenHash = hashRefreshToken(refreshToken);

  // Find the session first
  const existingSession = await db.query.sessions.findFirst({
    where: and(eq(sessions.refreshTokenHash, refreshTokenHash), isNull(sessions.revokedAt)),
  });

  if (!existingSession) {
    return false;
  }

  // Revoke the session
  await db
    .update(sessions)
    .set({
      revokedAt: new Date(),
      revokeReason: 'logout',
      lastUsedAt: new Date(),
    })
    .where(eq(sessions.id, existingSession.id));

  return true;
}
