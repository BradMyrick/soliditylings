import React, { useMemo } from "react";
import { Box, Text } from "ink";
import { clip } from "./ExercisePane.js";

interface Props {
    output: string;
    status: "running" | "pass" | "fail";
    timedOut: boolean;
    width: number;
    height: number;
    scrollFromBottom: number;
}

/**
 * Renders forge output, semantically colorized (we run forge with its
 * color stripped — piping disables it — and re-color by meaning, which
 * stays consistent inside a pane). j/k scroll; the view follows the
 * tail while scrollFromBottom is 0.
 */
export function OutputPane({ output, status, timedOut, width, height, scrollFromBottom }: Props) {
    const allLines = useMemo(() => output.split("\n"), [output]);

    const end = Math.max(0, allLines.length - scrollFromBottom);
    const visible = allLines.slice(Math.max(0, end - height), end);

    const borderColor = status === "pass" ? "green" : status === "fail" ? "red" : "gray";
    const titleColor = borderColor;

    const header =
        status === "running"
            ? " forge test — running… "
            : status === "pass"
              ? " forge test — PASS ✓ "
              : timedOut
                ? " forge test — TIMEOUT ⚠ "
                : " forge test — FAIL ✗ ";

    return (
        <Box flexDirection="column" width={width + 2} flexGrow={1}>
            <Text bold color={titleColor}>
                {header}
            </Text>
            <Box flexDirection="column" borderStyle="round" borderColor={borderColor} paddingLeft={1}>
                {visible.length === 0 && (
                    <Text dimColor>{status === "running" ? "compiling…" : "(no output)"}</Text>
                )}
                {visible.map((line, i) => {
                    const rendered = colorize(line, width - 2);
                    return <Text key={i} wrap="truncate">{rendered}</Text>;
                })}
                {scrollFromBottom > 0 && (
                    <Text dimColor>↑ {scrollFromBottom} lines above tail · j/k scroll · esc to end </Text>
                )}
            </Box>
        </Box>
    );
}

/** One colored line per source line, classified by meaning. */
function colorize(line: string, width: number): React.ReactNode {
    const text = clip(line, Math.max(0, width - 1));
    if (line.includes("[PASS")) return <Text color="green">{text}</Text>;
    if (line.includes("[FAIL")) return <Text color="red" bold>{text}</Text>;
    if (line.includes("Suite result: ok")) return <Text color="green" dimColor>{text}</Text>;
    if (line.includes("Suite result: FAILED")) return <Text color="red" dimColor>{text}</Text>;
    if (/^Error|Compiler run failed|Failing tests|failed; /i.test(line)) return <Text color="red">{text}</Text>;
    if (/^Warning|Warning \(/.test(line)) return <Text color="yellow" dimColor>{text}</Text>;
    if (/-->/ .test(line) || /^\s*\|/.test(line) || /^\s*\^/.test(line)) return <Text color="cyan" dimColor>{text}</Text>;
    if (/^Ran \d+ tests? for /.test(line)) return <Text bold dimColor>{text}</Text>;
    if (/tests? passed|tests? succeeded|tests? failed/i.test(line)) return <Text bold>{text}</Text>;
    return <Text dimColor>{text}</Text>;
}
