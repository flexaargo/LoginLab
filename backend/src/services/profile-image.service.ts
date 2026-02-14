import { S3Client } from 'bun';
import { env } from '../env';

const s3 = new S3Client({
  bucket: env.S3_BUCKET,
  region: env.S3_REGION,
  endpoint: env.S3_ENDPOINT,
  accessKeyId: env.S3_ACCESS_KEY_ID,
  secretAccessKey: env.S3_SECRET_ACCESS_KEY,
});

const supportedMimeTypes = new Map<string, string>([
  ['image/png', 'png'],
  ['image/jpeg', 'jpg'],
  ['image/jpg', 'jpg'],
]);

function parseBase64Image(imageBase64: string): Uint8Array {
  const bytes = Uint8Array.from(Buffer.from(imageBase64, 'base64'));
  if (bytes.length === 0) {
    throw new Error('Image payload is empty');
  }
  return bytes;
}

function extensionForMimeType(mimeType: string): string {
  const ext = supportedMimeTypes.get(mimeType);
  if (!ext) {
    throw new Error('Unsupported image MIME type');
  }
  return ext;
}

export async function uploadProfileImage(
  userId: string,
  imageBase64: string,
  mimeType: string,
): Promise<string> {
  const bytes = parseBase64Image(imageBase64);
  const ext = extensionForMimeType(mimeType);
  const key = `${profileImagesPrefix(userId)}${crypto.randomUUID()}.${ext}`;

  await s3.write(key, bytes, {
    type: mimeType,
  });

  return key;
}

function profileImagesPrefix(userId: string): string {
  return `profile-images/${userId}/`;
}

export async function deleteProfileImagesForUser(userId: string): Promise<void> {
  const prefix = profileImagesPrefix(userId);
  let continuationToken: string | undefined;

  do {
    const page = await s3.list({
      prefix,
      continuationToken,
      maxKeys: 1000,
    });

    const keys = page.contents?.map((object) => object.key) ?? [];
    await Promise.all(keys.map((key) => s3.delete(key)));

    continuationToken = page.nextContinuationToken;
  } while (continuationToken);
}

export async function profileImageUrlFromKey(
  profileImageKey: string | null | undefined,
): Promise<string | null> {
  if (!profileImageKey) {
    return null;
  }

  // Signed GET URL for private bucket access.
  return s3.presign(profileImageKey, { expiresIn: env.S3_SIGNED_URL_EXPIRES_SECONDS });
}
