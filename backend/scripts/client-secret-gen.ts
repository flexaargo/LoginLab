import { SignJWT, importPKCS8 } from 'jose';
import { readFile } from 'node:fs/promises';
import { basename } from 'node:path';

const APPLE_AUDIENCE = 'https://appleid.apple.com';
const MAX_EXP_SECONDS = 15_777_000; // Apple max: six months

type Args = Readonly<{
  keyPath?: string;
  kid?: string;
  teamId?: string;
  sub?: string;
  expSeconds?: number;
  json?: boolean;
  help?: boolean;
}>;

function parseArgs(argv: string[]): Args {
  const out: {
    keyPath?: string;
    kid?: string;
    teamId?: string;
    sub?: string;
    expSeconds?: number;
    json?: boolean;
    help?: boolean;
  } = {};

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--help' || a === '-h') out.help = true;
    else if (a === '--json') out.json = true;
    else if (a === '--key' || a === '--key-path') out.keyPath = argv[++i];
    else if (a === '--kid') out.kid = argv[++i];
    else if (a === '--team-id' || a === '--iss') out.teamId = argv[++i];
    else if (a === '--sub') out.sub = argv[++i];
    else if (a === '--exp-seconds') {
      const v = argv[++i];
      const n = v ? Number(v) : NaN;
      if (!Number.isFinite(n) || n <= 0) {
        throw new Error(`Invalid --exp-seconds value: ${JSON.stringify(v)}`);
      }
      out.expSeconds = Math.floor(n);
    } else if (a?.startsWith('--')) {
      throw new Error(`Unknown option: ${a}`);
    }
  }

  return out;
}

function usage(exitCode: number): never {
  const text = `
Generate an Apple Account/Org Data Sharing JWT (ES256).

Required:
  --key <path>        Path to .p8 private key (PKCS#8 PEM)
  --team-id <teamId>  10-char Apple Developer Team ID (iss)
  --sub <subject>     App ID / Services ID (client_id), case-sensitive

Optional:
  --kid <kid>         10-char key identifier (derived from key name if possible)
  --exp-seconds <n>   Token lifetime in seconds (default: 15552000 = 180 days)
  --json              Also print decoded header/payload to stderr
  -h, --help          Show help

Environment variable equivalents (used if args not provided):
  APPLE_KEY_PATH, APPLE_KID, APPLE_TEAM_ID, APPLE_SUB, APPLE_EXP_SECONDS

Examples:
  bun run scripts/client-secret-gen.ts \\
    --key ./secret/AuthKey_XXXXXXXXXX.p8 \\
    --kid ABC123DEFG \\
    --team-id DEF123GHIJ \\
    --sub com.mytest.app
`.trim();

  console.log(text);
  process.exit(exitCode);
}

function requireValue(name: string, value: string | undefined): string {
  if (!value) throw new Error(`Missing required value: ${name}`);
  return value;
}

function isTenChars(value: string): boolean {
  return value.length === 10;
}

function deriveKidFromKeyPath(keyPath: string): string | undefined {
  // Apple downloads: AuthKey_<KID>.p8 (KID is 10 chars)
  const name = basename(keyPath);
  const match = /^AuthKey_([A-Za-z0-9]{10})\.p8$/i.exec(name);
  return match?.[1];
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) usage(0);

  const keyPath = args.keyPath ?? process.env.APPLE_KEY_PATH;
  const teamId = args.teamId ?? process.env.APPLE_TEAM_ID;
  const sub = args.sub ?? process.env.APPLE_SUB;

  const expSecondsRaw =
    args.expSeconds ??
    (process.env.APPLE_EXP_SECONDS ? Number(process.env.APPLE_EXP_SECONDS) : undefined) ??
    60 * 60 * 24 * 180; // 180 days by default

  const expSeconds = Math.floor(expSecondsRaw);
  if (!Number.isFinite(expSeconds) || expSeconds <= 0) {
    throw new Error(`Invalid exp seconds: ${expSecondsRaw}`);
  }
  if (expSeconds > MAX_EXP_SECONDS) {
    throw new Error(`expSeconds (${expSeconds}) exceeds Apple max (${MAX_EXP_SECONDS})`);
  }

  const resolvedKeyPath = requireValue('--key / APPLE_KEY_PATH', keyPath);
  const resolvedTeamId = requireValue('--team-id / APPLE_TEAM_ID', teamId);
  const resolvedSub = requireValue('--sub / APPLE_SUB', sub);

  const derivedKid = deriveKidFromKeyPath(resolvedKeyPath);
  const resolvedKid =
    args.kid ?? process.env.APPLE_KID ?? derivedKid ?? requireValue('--kid / APPLE_KID', undefined);

  if (!isTenChars(resolvedKid)) {
    throw new Error(`kid must be 10 characters, got: ${resolvedKid.length}`);
  }
  if (!isTenChars(resolvedTeamId)) {
    throw new Error(`teamId (iss) must be 10 characters, got: ${resolvedTeamId.length}`);
  }

  const pem = await readFile(resolvedKeyPath, 'utf8');
  const privateKey = await importPKCS8(pem, 'ES256');

  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + expSeconds;

  const jwt = await new SignJWT({
    iss: resolvedTeamId,
    iat,
    exp,
    aud: APPLE_AUDIENCE,
    sub: resolvedSub,
  })
    .setProtectedHeader({ alg: 'ES256', kid: resolvedKid })
    .sign(privateKey);

  // stdout: JWT only (easy to pipe)
  console.log(jwt);

  if (args.json) {
    const header = { alg: 'ES256', kid: resolvedKid };
    const payload = {
      iss: resolvedTeamId,
      iat,
      exp,
      aud: APPLE_AUDIENCE,
      sub: resolvedSub,
    };
    console.error(JSON.stringify({ header, payload }, null, 2));
  }
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(message);
  usage(1);
});
