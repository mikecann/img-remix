import { execFileSync } from 'child_process';

// The command that opens a file or folder in its default app.
//
// Windows goes straight to explorer.exe. `cmd /c start` would run anything after
// an & in the path, and generated file names come from the input image's name.
// Windows names can't contain ", so quoting the path here is safe, and it stops
// explorer.exe splitting the path at a comma.
export function openCommand(target: string, platform: NodeJS.Platform = process.platform): string[] {
  return platform === 'win32' ? ['explorer.exe', `"${target}"`] : ['open', target];
}

export function openPath(target: string): void {
  const [command, ...args] = openCommand(target);
  if (process.platform === 'win32') {
    // Pass the quoted path through untouched. explorer.exe exits with 1 even
    // when it opens the file, so its exit code means nothing.
    Bun.spawnSync([command!, ...args], { windowsVerbatimArguments: true });
    return;
  }
  execFileSync(command!, args, { stdio: 'inherit' });
}
