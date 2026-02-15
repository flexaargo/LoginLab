<p align="center">
  <img src="resources/LoginLabIcon.png" alt="Login Lab Icon" width="128" height="128" />
</p>

# Login Lab

`Login Lab` is a reference project for building Sign in with Apple with:

- a native iOS app (`mobile/`) built with SwiftUI
- a backend API (`backend/`) built with Bun + Hono + Postgres
- session-based auth (access + refresh tokens)
- basic account management (read profile, update profile, sign out, delete account)

## Project Structure

- `mobile/` iOS app source (`LoginLab.xcodeproj`)
- `backend/` Bun API, database schema, auth routes, and Apple token validation

## Prerequisites

- macOS with Xcode installed
- Bun (v1.3+ recommended)
- Postgres database
- Apple Developer account + Sign in with Apple capability enabled for your app ID
- S3-compatible object storage bucket (AWS S3, Cloudflare R2, MinIO, etc.) for profile images

## Backend Setup

1. Install dependencies:

```bash
cd backend
bun install
```

2. Create your env file:

```bash
cp .env.example .env
```

3. Fill in required environment variables in `backend/.env`:

- `DATABASE_URL`
- `APPLE_CLIENT_ID` (must match your iOS bundle identifier used for Sign in with Apple)
- `APPLE_CLIENT_SECRET`
- `JWT_SECRET`
- `REFRESH_TOKEN_PEPPER`
- `S3_BUCKET`
- `S3_REGION`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`
- optional: `S3_ENDPOINT`, `S3_SIGNED_URL_EXPIRES_SECONDS`

4. (Optional helper) Generate Apple client secret JWT:

```bash
bun run jwt:apple --key ./secret/AuthKey_<KID>.p8 --team-id <TEAM_ID> --sub <BUNDLE_ID>
```

Copy the generated JWT into `APPLE_CLIENT_SECRET`.

5. Create/update database schema (Drizzle):

```bash
bunx drizzle-kit push
```

6. Start the backend server:

```bash
bun run dev
```

By default, the API runs on `http://localhost:3000`.

## iOS App Setup

1. Open the Xcode project:

```bash
open mobile/LoginLab.xcodeproj
```

2. In Xcode, verify:

- `Signing & Capabilities` has your team selected
- Bundle identifier matches the backend `APPLE_CLIENT_ID`
- Sign in with Apple capability is enabled

3. Configure API host in `mobile/LoginLab/Sources/NetworkingClientProvider.swift`:

- set `host`, `port`, and `scheme` to your backend
- for simulator on the same Mac, `localhost` is usually enough
- for a physical device, use your machine LAN hostname/IP and ensure port `3000` is reachable

4. Run the `LoginLab` scheme from Xcode.

## API Overview

Auth routes are under `/auth`:

- `POST /auth/signin`
- `POST /auth/refresh`
- `POST /auth/signout`
- `POST /auth/delete-account`
- `PATCH /auth/profile`
- `GET /auth/me`

## Notes

- Profile images are stored in S3-compatible object storage and returned as signed URLs.
- The backend verifies Apple identity tokens server-side and exchanges authorization codes with Apple.
