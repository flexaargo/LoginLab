import z from 'zod';
import { env } from '../env';
import { createRemoteJWKSet, jwtVerify } from 'jose';

// Video from WWDC: https://developer.apple.com/videos/play/wwdc2022/10122/

/** Apple's public keys endpoint. */
const APPLE_KEYS_URL = new URL('https://appleid.apple.com/auth/keys');
const APPLE_ISSUER = 'https://appleid.apple.com';
/** Apple's public keys JWKS. */
const applePublicKeys = createRemoteJWKSet(APPLE_KEYS_URL);

/** Schema for the identity token payload which is provided by Sign in with Apple and through the app request. */
const appleIdentityTokenSchema = z.object({
  /** Issuer of the token. Always `https://appleid.apple.com`. */
  iss: z.string(),
  /** Audience field. Always app bundle identifier. */
  aud: z.string(),
  /** Expiration time of the token. */
  exp: z.number(),
  /** Issued at time of the token. */
  iat: z.number(),
  /** Subject of the token. Always the user identifier which is assigned by Apple. */
  sub: z.string(),
  /** Email address of the user if it was requested. */
  email: z.email().optional(),
  /** Whether the email address has been verified. */
  email_verified: z.boolean().optional(),
  /** Nonce used for the authentication request. */
  nonce: z.string().optional(),
  /** Whether the nonce is supported. */
  nonce_supported: z.boolean(),
});

/** The payload of the Apple identity JWT. */
type AppleIdentityTokenPayload = z.infer<typeof appleIdentityTokenSchema>;

/** Verify the Apple identity JWT and return the payload if it is valid. */
export async function verifyAppleIdentityToken(
  identityToken: string,
  nonce: string,
): Promise<AppleIdentityTokenPayload> {
  const clientId = env.APPLE_CLIENT_ID;

  try {
    const { payload } = await jwtVerify(identityToken, applePublicKeys, {
      issuer: APPLE_ISSUER,
      audience: clientId,
    });
    const validated = appleIdentityTokenSchema.parse(payload);
    const expiration = new Date(validated.exp * 1000); // Apple uses seconds since epoch.
    if (expiration < new Date()) throw new Error('Apple identity token has expired');
    if (validated.nonce_supported && validated.nonce !== nonce) throw new Error('Invalid nonce');
    return validated;
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    throw new Error(`Invalid Apple token: ${message}`);
  }
}

const appleAuthorizationCodeExchangeSchema = z.object({
  access_token: z.string(),
  expires_in: z.number(),
  id_token: z.string(),
  refresh_token: z.string(),
});

type AppleAuthorizationCodeExchangeResponse = z.infer<typeof appleAuthorizationCodeExchangeSchema>;

export async function exchangeAppleAuthorizationCode(
  authorizationCode: string,
): Promise<AppleAuthorizationCodeExchangeResponse> {
  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code: authorizationCode,
    client_id: env.APPLE_CLIENT_ID,
    client_secret: env.APPLE_CLIENT_SECRET,
  });

  const result = await fetch('https://appleid.apple.com/auth/token', {
    method: 'POST',
    body,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  });

  if (!result.ok) {
    const text = await result.text();
    throw new Error(`Failed to exchange Apple authorization code: ${result.status} - ${text}`);
  }

  const data = await result.json();
  const validated = appleAuthorizationCodeExchangeSchema.parse(data);
  return validated;
}

/**
 * Revokes a refresh token with Apple.
 * Call this before deleting user data so the user's Apple ID is unlinked from the app.
 * @see https://developer.apple.com/documentation/sign_in_with_apple/revoking_tokens
 */
export async function revokeAppleToken(refreshToken: string): Promise<void> {
  const body = new URLSearchParams({
    client_id: env.APPLE_CLIENT_ID,
    client_secret: env.APPLE_CLIENT_SECRET,
    token: refreshToken,
    token_type_hint: 'refresh_token',
  });

  const result = await fetch('https://appleid.apple.com/auth/revoke', {
    method: 'POST',
    body,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  });

  if (!result.ok) {
    const text = await result.text();
    throw new Error(`Failed to revoke Apple token: ${result.status} - ${text}`);
  }
}
