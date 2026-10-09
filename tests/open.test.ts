import { afterEach, expect, test } from 'bun:test';
import { chmodSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { openCommand } from '../open';

const dirs: string[] = [];
afterEach(() => { for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true }); });

// Generated names come from the input file's name, which can hold & or a comma.
test('Windows opens through explorer.exe with the whole path quoted, never cmd.exe', () => {
  const path = 'C:\\Users\\me\\Downloads\\x&calc&,evil.exe-generated-001.png';
  expect(openCommand(path, 'win32')).toEqual(['explorer.exe', `"${path}"`]);
});

// `folder` opens D:\ for an image at the top of a drive.
test('Windows passes a drive root to explorer.exe without quotes', () => {
  expect(openCommand('D:\\', 'win32')).toEqual(['explorer.exe', 'D:\\']);
  expect(openCommand('D:\\photos', 'win32')).toEqual(['explorer.exe', '"D:\\photos"']);
});

// `folder` opens \\server\share\ for an image at the top of a network share. Quoted
// with its trailing \, the closing quote would read as an escaped quote.
test('Windows drops the trailing backslash from a UNC share root before quoting it', () => {
  expect(openCommand('\\\\server\\share\\', 'win32')).toEqual(['explorer.exe', '"\\\\server\\share"']);
  expect(openCommand('\\\\server\\share\\photos', 'win32')).toEqual(['explorer.exe', '"\\\\server\\share\\photos"']);
});

test('macOS hands the path to open as a single argument', () => {
  expect(openCommand('/tmp/a&b, c.png', 'darwin')).toEqual(['open', '/tmp/a&b, c.png']);
});

test.skipIf(process.platform === 'win32')('openPath runs open with the path unchanged', () => {
  const dir = mkdtempSync(join(tmpdir(), 'img-remix open '));
  dirs.push(dir);
  const fakeOpen = join(dir, 'open');
  writeFileSync(fakeOpen, '#!/bin/bash\nfor a in "$@"; do printf "<%s>\\n" "$a"; done\n');
  chmodSync(fakeOpen, 0o755);
  const target = join(dir, 'in&put; $(echo no)-generated-001.png');
  const result = Bun.spawnSync(
    [process.execPath, '-e', `import { openPath } from ${JSON.stringify(join(import.meta.dirname, '../open.ts'))}; openPath(process.argv.at(-1)!);`, target],
    { env: { ...process.env, PATH: `${dir}:${process.env.PATH}` } },
  );
  expect(result.exitCode).toBe(0);
  expect(result.stdout.toString()).toBe(`<${target}>\n`);
});
