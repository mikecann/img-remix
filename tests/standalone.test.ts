import { afterEach, expect, test } from 'bun:test';
import { mkdtempSync, copyFileSync, writeFileSync, symlinkSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const dirs: string[] = [];
afterEach(() => { for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true }); });

test('one-shot CLI loads its own .env from another working directory and uses the standalone identity', () => {
  const dir = mkdtempSync(join(tmpdir(), 'img-remix test '));
  dirs.push(dir);
  copyFileSync(join(import.meta.dirname, '../index.ts'), join(dir, 'index.ts'));
  copyFileSync(join(import.meta.dirname, '../open.ts'), join(dir, 'open.ts'));
  symlinkSync(join(import.meta.dirname, '../node_modules'), join(dir, 'node_modules'), process.platform === 'win32' ? 'junction' : 'dir');
  writeFileSync(join(dir, '.env'), 'OPENROUTER_API_KEY=offline-test-key\n');
  writeFileSync(join(dir, 'input image.png'), 'reference');
  writeFileSync(join(dir, 'mock.ts'), `
    globalThis.fetch = async (_url, options) => {
      const headers = options.headers;
      if (headers.Authorization !== 'Bearer offline-test-key') throw new Error('Wrong .env');
      if (headers['HTTP-Referer'] !== 'https://github.com/mikecann/img-remix') throw new Error('Wrong referer');
      if (headers['X-Title'] !== 'img-remix') throw new Error('Wrong title');
      const body = JSON.parse(options.body);
      if (body.messages[0].content[1].text !== 'Make it blue') throw new Error('Wrong prompt');
      return Response.json({ choices: [{ message: { images: [{ image_url: { url: 'data:image/png;base64,b2ZmbGluZS1yZXN1bHQ=' } }] } }] });
    };
  `);
  const env = { ...process.env };
  delete env.OPENROUTER_API_KEY;
  const result = Bun.spawnSync([process.execPath, '--preload', join(dir, 'mock.ts'), join(dir, 'index.ts'), join(dir, 'input image.png'), '--prompt', 'Make it blue'], { cwd: tmpdir(), env });
  expect(result.exitCode).toBe(0);
  expect(result.stdout.toString()).toContain('IMG REMIX');
  expect(result.stderr.toString()).not.toContain('ERROR');
  expect(readFileSync(join(dir, 'input image-generated-001.png'), 'utf8')).toBe('offline-result');
});

test('one-shot CLI exits non-zero when every variation fails', () => {
  const dir = mkdtempSync(join(tmpdir(), 'img-remix test '));
  dirs.push(dir);
  copyFileSync(join(import.meta.dirname, '../index.ts'), join(dir, 'index.ts'));
  copyFileSync(join(import.meta.dirname, '../open.ts'), join(dir, 'open.ts'));
  symlinkSync(join(import.meta.dirname, '../node_modules'), join(dir, 'node_modules'), process.platform === 'win32' ? 'junction' : 'dir');
  writeFileSync(join(dir, '.env'), 'OPENROUTER_API_KEY=offline-test-key\n');
  writeFileSync(join(dir, 'input image.png'), 'reference');
  writeFileSync(join(dir, 'mock.ts'), `
    globalThis.fetch = async () => Response.json({ error: { message: 'Missing Authentication header', code: 401 } }, { status: 401 });
  `);
  const env = { ...process.env };
  delete env.OPENROUTER_API_KEY;
  const result = Bun.spawnSync([process.execPath, '--preload', join(dir, 'mock.ts'), join(dir, 'index.ts'), join(dir, 'input image.png'), '--prompt', 'Make it blue'], { cwd: tmpdir(), env });
  expect(result.exitCode).not.toBe(0);
  expect(result.stderr.toString()).toContain('ERROR');
});
