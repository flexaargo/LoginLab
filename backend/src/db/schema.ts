import { relations } from 'drizzle-orm';
import { index, pgEnum, pgTable, text, timestamp, uniqueIndex, uuid } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),

  fullName: text('full_name').notNull(),
  email: text('email').notNull().unique(),
  displayName: text('display_name').notNull(),

  profileImageUrl: text('profile_image_url'),

  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const identityProvidersEnum = pgEnum('identity_providers', ['apple']);

export const identities = pgTable(
  'identities',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),

    provider: identityProvidersEnum('provider').notNull(),

    // For Apple: the user identifier assigned by Apple
    providerUserId: text('provider_user_id'),

    // For email/password & magic links: normalized email
    // For phone: E.164 number like +14155552671
    identifier: text('identifier'),

    // For password auth: password hash (argon2id)
    secretHash: text('secret_hash'),

    providerRefreshTokenEnc: text('provider_refresh_token_enc'),
    providerRefreshTokenUpdatedAt: timestamp('provider_refresh_token_updated_at'),

    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (t) => [
    uniqueIndex('identities_provider_user_unique').on(t.provider, t.providerUserId),
    uniqueIndex('identities_provider_identifier_unique').on(t.provider, t.identifier),
    index('identities_user_id_idx').on(t.userId),
  ],
);

export const sessions = pgTable('sessions', {
  id: uuid('id').defaultRandom().primaryKey(),

  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),

  refreshTokenHash: text('refresh_token_hash').notNull().unique(),
  refreshTokenExpiresAt: timestamp('refresh_token_expires_at').notNull(),

  createdAt: timestamp('created_at').defaultNow().notNull(),
  lastUsedAt: timestamp('last_used_at'),
  revokedAt: timestamp('revoked_at'),
  revokeReason: text('revoke_reason'),
  replacedBySessionId: uuid('replaced_by_session_id'),

  userAgent: text('user_agent'),
  deviceName: text('device_name'),
  ipAddress: text('ip_address'),
});

export const userRelations = relations(users, ({ many }) => ({
  identities: many(identities),
  sessions: many(sessions),
}));

export const identitiesRelations = relations(identities, ({ one }) => ({
  user: one(users, {
    fields: [identities.userId],
    references: [users.id],
  }),
}));

export const sessionsRelations = relations(sessions, ({ one }) => ({
  user: one(users, {
    fields: [sessions.userId],
    references: [users.id],
  }),
}));
