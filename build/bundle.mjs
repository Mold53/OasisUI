// bundles src/**/*.lua into dist/OasisUI.lua
// every module is a chunk that starts with `local import = ...` and returns its value
// usage: node build/bundle.mjs
import { readFileSync, writeFileSync, readdirSync, statSync, mkdirSync } from "node:fs";
import { dirname, join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const srcDir = join(root, "src");
const pkg = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));

function walk(dir) {
    return readdirSync(dir).flatMap((name) => {
        const full = join(dir, name);
        return statSync(full).isDirectory() ? walk(full) : name.endsWith(".lua") ? [full] : [];
    });
}

const files = walk(srcDir).sort();
const parts = [
    `-- OasisUI v${pkg.version} | ${pkg.license} License | ${pkg.homepage}`,
    `-- generated from src/ by build/bundle.mjs, do not edit`,
    `local __modules, __cache = {}, {}`,
    `local function import(name)`,
    `    local cached = __cache[name]`,
    `    if cached == nil then`,
    `        local loader = __modules[name]`,
    `        if not loader then error("[OasisUI] missing module " .. name, 2) end`,
    `        cached = loader(import)`,
    `        if cached == nil then cached = false end`,
    `        __cache[name] = cached`,
    `    end`,
    `    return cached`,
    `end`,
    ``,
];

for (const file of files) {
    const name = relative(srcDir, file).split(sep).join("/").replace(/\.lua$/, "");
    const body = readFileSync(file, "utf8").replace(/\r\n/g, "\n").trimEnd();
    parts.push(`__modules["${name}"] = function(...)`, body, `end`, ``);
}

parts.push(`local Library = import("init")`, `Library.Version = "${pkg.version}"`, `return Library`, ``);

mkdirSync(join(root, "dist"), { recursive: true });
writeFileSync(join(root, "dist/OasisUI.lua"), parts.join("\n"));
console.log(`dist/OasisUI.lua: ${files.length} modules`);
