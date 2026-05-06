import * as esbuild from "esbuild";
import * as path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Use esbuild from the matrix-link-language node_modules if needed
const ad4mLdkEntry = process.env.AD4M_LDK_ENTRY ||
    path.resolve(__dirname, "../../../../coasys/ad4m/ad4m-ldk/js/lib/index.js");

const ad4mLdkAliasPlugin = {
    name: "ad4m-ldk-alias",
    setup(build) {
        build.onResolve({ filter: /^ad4m:host$/ }, () => ({
            path: "ad4m:host",
            external: true,
        }));
        build.onResolve({ filter: /^@coasys\/ad4m-ldk$/ }, () => ({
            path: ad4mLdkEntry,
            namespace: "file",
        }));
    },
};

await esbuild.build({
    entryPoints: [path.resolve(__dirname, "index.ts")],
    outfile: path.resolve(__dirname, "build/bundle.js"),
    bundle: true,
    platform: "neutral",
    target: "es2022",
    format: "esm",
    charset: "ascii",
    plugins: [ad4mLdkAliasPlugin],
});

console.log("✅ local-neighbourhood-language bundle written");
