import { execFileSync } from 'child_process';

// The command that opens a file or folder in its default app.
//
// Windows goes straight to explorer.exe. `cmd /c start` would run anything after
// an & in the path, and generated file names come from the input image's name.
// Windows names can't contain ", so quoting the path here is safe, and it stops
// explorer.exe splitting the path at a comma. A quoted path must not end in \,
// because "D:\" ends in \" and some parsers read that as an escaped quote. So a
// drive root like D:\ is left bare, and any other trailing \ (a network share
// root like \\server\share\) is dropped before quoting.
export function openCommand(target: string, platform: NodeJS.Platform = process.platform): string[] {
  if (platform !== 'win32') return ['open', target];
  if (/^[a-z]:\\$/i.test(target)) return ['explorer.exe', target];
  return ['explorer.exe', `"${target.replace(/\\+$/, '')}"`];
}

export function openPath(target: string): void {
  const [command, ...args] = openCommand(target);
  if (process.platform === 'win32') {
    // Pass the quoted path through untouched (needs Bun 1.1.4 or newer).
    // explorer.exe exits with 1 even when it opens the file, so its exit code
    // means nothing. Ignore its output so a viewer it starts can't hold a pipe
    // open and block the prompt.
    Bun.spawnSync([command!, ...args], {
      windowsVerbatimArguments: true,
      stdin: 'ignore',
      stdout: 'ignore',
      stderr: 'ignore',
    });
    return;
  }
  execFileSync(command!, args, { stdio: 'inherit' });
}
