import { spawnSync } from "node:child_process";

const godotExecutable = process.env.GODOT_BIN || "godot";
const result = spawnSync(
  godotExecutable,
  ["--headless", "--path", ".", "--quit-after", "15"],
  { stdio: "inherit" }
);

if (result.error) {
  console.error(`Could not start Godot executable '${godotExecutable}': ${result.error.message}`);
  console.error("Set GODOT_BIN to the installed Godot executable path.");
  process.exitCode = 1;
} else {
  process.exitCode = result.status ?? 1;
}
