import React, { useMemo } from "react";
import { Box, Text } from "ink";

interface Props {
    title: string;
    source: string;
    width: number;
    height: number;
    flash?: boolean;
}

const GUTTER = 7; // "  12 │ " — padStart(4) + " │ "

/**
 * Renders the exercise source with line numbers. The view auto-centers on
 * the first TODO line — that's where the learner works. TODO lines are
 * highlighted; everything else is calm.
 */
export function ExercisePane({ title, source, width, height, flash }: Props) {
    const lines = useMemo(() => source.split("\n"), [source]);

    const firstTodo = lines.findIndex((l) => l.includes("TODO"));
    const anchor = firstTodo === -1 ? 0 : Math.max(0, firstTodo - 3);
    const maxStart = Math.max(0, lines.length - height);
    const start = Math.min(anchor, maxStart);
    const visible = lines.slice(start, start + height);

    const borderColor = flash ? "green" : "cyan";

    return (
        <Box flexDirection="column" width={width + 2}>
            <Text bold color={flash ? "green" : "cyan"}>
                {` ${title} `.slice(0, width)}
            </Text>
            <Box flexDirection="column" borderStyle="round" borderColor={borderColor} paddingLeft={1}>
                {visible.map((line, i) => {
                    const num = start + i + 1;
                    const isTodo = line.includes("TODO");
                    const clipped = clip(line, width - GUTTER - 1);
                    return (
                        <Text key={i} color={isTodo ? "yellow" : undefined} bold={isTodo} wrap="truncate">
                            <Text dimColor>{String(num).padStart(4)} │ </Text>
                            {isTodo ? clipped : <Text dimColor={isComment(line)}>{clipped}</Text>}
                        </Text>
                    );
                })}
                {visible.length === 0 && <Text dimColor>(empty file)</Text>}
            </Box>
        </Box>
    );
}

function isComment(line: string): boolean {
    const t = line.trim();
    return t.startsWith("//") || t.startsWith("/*") || t.startsWith("*");
}

export function clip(s: string, max: number): string {
    // Assume no wide chars in exercise sources (true for this curriculum).
    if (s.length <= max) return s;
    return s.slice(0, Math.max(0, max - 1)) + "…";
}
