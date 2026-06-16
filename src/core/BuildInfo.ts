export const buildInfo = {
  ref: (import.meta.env.VITE_BUILD_REF ?? "locale").slice(0, 7),
  time: import.meta.env.VITE_BUILD_TIME ?? "sviluppo locale",
};
