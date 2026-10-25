import { render } from "ink";
import * as path from "node:path";
import chokidar from "chokidar";
import { PROJECT_ROOT, getExercises } from "../state.js";
import { bus } from "./bus.js";
import { App } from "./App.js";

/**
 * Mount the fullscreen TUI and watch the exercises tree. Editing any
 * exercise file focuses and re-runs it.
 */
export async function runWatch(): Promise<void> {
    const exercises = getExercises();
    const byAbsPath = new Map<string, string>();
    for (const e of exercises) {
        byAbsPath.set(path.resolve(PROJECT_ROOT, e.path), e.name);
    }

    let timer: NodeJS.Timeout | null = null;
    let lastName: string | null = null;

    const watcher = chokidar.watch(path.resolve(PROJECT_ROOT, "exercises"), {
        ignored: /(^|[\/\\])\..|~$|\.swp$/,
        persistent: true,
        ignoreInitial: true,
    });

    watcher.on("all", (_event, filePath: string) => {
        if (!filePath.endsWith(".sol")) return;
        const name = byAbsPath.get(path.resolve(filePath));
        if (!name) return;
        lastName = name;
        if (timer) clearTimeout(timer);
        timer = setTimeout(() => {
            if (lastName) bus.emit(lastName);
        }, 150);
    });

    const { waitUntilExit } = render(<App />, { exitOnCtrlC: true });

    await waitUntilExit();
    await watcher.close();
}
