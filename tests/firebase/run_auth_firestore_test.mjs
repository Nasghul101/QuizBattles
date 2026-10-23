import { spawnSync } from "node:child_process";

const godotExecutable = process.env.GODOT_BIN || "godot";
const script = process.argv[2] || "tests/firebase_auth_firestore_rules_test.gd";
const result = spawnSync(
  godotExecutable,
  ["--headless", "--path", ".", "--script", script],
  { stdio: "inherit" }
);

if (result.error) {
  console.error(`Could not start Godot executable '${godotExecutable}': ${result.error.message}`);
  console.error("Set GODOT_BIN to the installed Godot executable path.");
  process.exitCode = 1;
} else {
  process.exitCode = result.status ?? 1;
}
