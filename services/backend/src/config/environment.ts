const defaultPort = 3000;

function readPort(value: string | undefined): number {
  if (value === undefined || value.trim() === "") return defaultPort;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) {
    throw new Error("PORT must be an integer between 1 and 65535");
  }
  return parsed;
}

export const environment = Object.freeze({
  host: process.env.HOST?.trim() || "127.0.0.1",
  port: readPort(process.env.PORT),
  serviceName: "atheerautotrade-backend",
  applicationVersion: "0.1.0"
});
