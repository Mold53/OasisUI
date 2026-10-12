// regenerates src/Core/Icons.lua from a full lucide id map (Footagesus/Icons format)
// usage: node build/icons.mjs <path-to-lucide-icons.lua>
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = readFileSync(process.argv[2], "utf8");
const all = new Map([...src.matchAll(/\["([a-z0-9-]+)"\]\s*=\s*"(rbxassetid:\/\/\d+)"/g)].map((m) => [m[1], m[2]]));

const wanted = readFileSync(join(root, "build/icon-names.txt"), "utf8").split(/\s+/).filter(Boolean);
const missing = wanted.filter((n) => !all.has(n));
if (missing.length) console.warn("missing:", missing.join(" "));

const names = [...new Set(wanted.filter((n) => all.has(n)))].sort();
const width = Math.max(...names.map((n) => n.length)) + 4;
const lines = names.map((n) => `    ${(`["${n}"]`).padEnd(width)} = "${all.get(n)}",`);
const out = `-- lucide subset; regenerate with build/icons.mjs, extend at runtime with Library:AddIcons\nreturn {\n${lines.join("\n")}\n}\n`;
writeFileSync(join(root, "src/Core/Icons.lua"), out);
console.log(`${names.length} icons written`);
