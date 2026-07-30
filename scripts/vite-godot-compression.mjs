import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";
import {
  brotliCompress,
  constants as zlibConstants,
  gzip,
} from "node:zlib";

const compressBrotli = promisify(brotliCompress);
const compressGzip = promisify(gzip);
const COMPRESSIBLE = new Map([
  ["/godot/outdoor/index.wasm", "application/wasm"],
  ["/godot/outdoor/index.js", "text/javascript; charset=utf-8"],
]);

export function godotWebCompression() {
  const cache = new Map();

  function install(middlewares, sourceRoot) {
    middlewares.use(async (request, response, next) => {
      try {
        if (!["GET", "HEAD"].includes(request.method ?? "") || request.headers.range) {
          next();
          return;
        }
        const pathname = new URL(request.url ?? "/", "http://localhost").pathname;
        const contentType = COMPRESSIBLE.get(pathname);
        if (!contentType) {
          next();
          return;
        }
        const accepted = request.headers["accept-encoding"] ?? "";
        const encoding = accepted.includes("br") ? "br" : accepted.includes("gzip") ? "gzip" : "";
        if (!encoding) {
          next();
          return;
        }
        const sourcePath = path.join(sourceRoot, pathname.replace(/^\//, ""));
        const info = await stat(sourcePath);
        const cacheKey = `${sourcePath}:${info.mtimeMs}:${encoding}`;
        let body = cache.get(cacheKey);
        if (!body) {
          const source = await readFile(sourcePath);
          body = encoding === "br"
            ? await compressBrotli(source, {
              params: { [zlibConstants.BROTLI_PARAM_QUALITY]: 5 },
            })
            : await compressGzip(source, { level: 6 });
          cache.set(cacheKey, body);
        }
        response.statusCode = 200;
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Content-Encoding", encoding);
        response.setHeader("Content-Length", body.length);
        response.setHeader("Content-Type", contentType);
        response.setHeader("Vary", "Accept-Encoding");
        response.end(request.method === "HEAD" ? undefined : body);
      } catch (error) {
        if (error?.code === "ENOENT") {
          next();
          return;
        }
        next(error);
      }
    });
  }

  return {
    name: "eli-godot-web-compression",
    configureServer(server) {
      install(server.middlewares, path.resolve("public"));
    },
    configurePreviewServer(server) {
      install(server.middlewares, path.resolve("dist"));
    },
  };
}
