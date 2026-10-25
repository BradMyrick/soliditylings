import React from "react";
import { Box, Text } from "ink";

interface Props {
    solved: number;
    total: number;
    status: "running" | "pass" | "fail";
    width: number;
}

/** Progress bar + key legend. The quiet spine of the UI. */
export function Footer({ solved, total, status, width }: Props) {
    const pct = total === 0 ? 0 : solved / total;
    const barOuter = Math.max(10, Math.min(width - 34, 30));
    const filled = Math.round(pct * barOuter);
    const bar = "█".repeat(filled) + "░".repeat(barOuter - filled);

    const statusColor = status === "pass" ? "green" : status === "fail" ? "red" : "cyan";
    const statusText = status === "running" ? "···" : status === "pass" ? "PASS" : "FAIL";

    return (
        <Box flexDirection="column">
            <Box>
                <Text color={statusColor}>{statusText.padEnd(5)}</Text>
                <Text color={pct === 1 ? "green" : "magenta"}>{bar}</Text>
                <Text> {solved}/{total} ({Math.round(pct * 100)}%)</Text>
            </Box>
            <Text dimColor> n next · p prev · h hint · l list · r rerun · j/k scroll · q quit </Text>
        </Box>
    );
}
