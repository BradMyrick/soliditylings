import React, { useState } from "react";
import { Box, Text, useInput } from "ink";
import { Exercise } from "../state.js";

interface Props {
    exercises: Exercise[];
    solved: Set<string>;
    currentIdx: number;
    onSelect: (idx: number) => void;
    onClose: () => void;
}

/**
 * Fullscreen overlay: a scrollable list of every exercise with progress
 * markers. Arrows move, enter jumps, esc closes.
 */
export function ListView({ exercises, solved, currentIdx, onSelect, onClose }: Props) {
    const [sel, setSel] = useState(currentIdx);
    const [top, setTop] = useState(Math.max(0, currentIdx - 5));

    useInput(
        (input, key) => {
            if (key.upArrow) {
                const n = Math.max(0, sel - 1);
                setSel(n);
                if (n < top) setTop(n);
            } else if (key.downArrow) {
                const n = Math.min(exercises.length - 1, sel + 1);
                setSel(n);
                if (n >= top + 14) setTop(n - 13);
            } else if (key.return) {
                onSelect(sel);
            } else if (key.escape || input === "q" || input === "l") {
                onClose();
            } else if (input === "j") {
                const n = Math.min(exercises.length - 1, sel + 1);
                setSel(n);
                if (n >= top + 14) setTop(n - 13);
            } else if (input === "k") {
                const n = Math.max(0, sel - 1);
                setSel(n);
                if (n < top) setTop(n);
            }
        },
        { isActive: true }
    );

    const visible = exercises.slice(top, top + 14);

    return (
        <Box flexDirection="column" alignItems="center" justifyContent="center" flexGrow={1}>
            <Box flexDirection="column" borderStyle="double" borderColor="cyan" paddingX={2} width={70}>
                <Text bold color="cyan"> exercises — {solved.size}/{exercises.length} solved</Text>
                <Text dimColor> ↑/↓ move · enter jump · esc close</Text>
                <Box flexDirection="column" marginTop={1}>
                    {visible.map((e, i) => {
                        const gi = top + i;
                        const isSel = gi === sel;
                        const done = solved.has(e.name);
                        const marker = done ? "✔" : "○";
                        const color = done ? "green" : "gray";
                        const row = `${marker} ${e.name}`;
                        return (
                            <Text key={e.name} color={color} inverse={isSel} wrap="truncate">
                                {isSel ? ` ${row} ` : ` ${row}`}
                            </Text>
                        );
                    })}
                </Box>
            </Box>
        </Box>
    );
}
