// Minimal event bus for wiring chokidar (outside React) into the App.
type Handler = (exerciseName: string) => void;

const handlers = new Set<Handler>();

export const bus = {
    emit(name: string) {
        handlers.forEach((h) => h(name));
    },
    subscribe(h: Handler): () => void {
        handlers.add(h);
        return () => {
            handlers.delete(h);
        };
    },
};
