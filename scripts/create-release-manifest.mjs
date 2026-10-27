#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFileSync, statSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const env = Object.fromEntries(
  readFileSync(path.join(root, "config", "build.env"), "utf8")
    .split(/\r?\n/)
    .filter((line) => line && !line.startsWith("#"))
    .map((line) => line.split(/=(.*)/s).slice(0, 2)),
);
const dist = path.join(root, "dist");
const tag =
  process.env.GITHUB_REF_NAME ?? `mobile-ffmpeg-${env.FFMPEG_MOBILE_VERSION}`;
const repository = env.PUBLIC_REPOSITORY;

const describe = (platform) => {
  const fileName = `gravae-ffmpeg-${platform}-${env.FFMPEG_MOBILE_VERSION}.tar.gz`;
  const filePath = path.join(dist, fileName);
  return {
    url: `https://github.com/${repository}/releases/download/${tag}/${fileName}`,
    sha256: createHash("sha256").update(readFileSync(filePath)).digest("hex"),
    size: statSync(filePath).size,
    archiveType: "tar.gz",
  };
};

const manifest = {
  schemaVersion: 1,
  version: env.FFMPEG_MOBILE_VERSION,
  tag,
  repository,
  ffmpeg: {
    version: env.FFMPEG_SOURCE_TAG,
    kitCommit: env.FFMPEG_KIT_COMMIT,
    license: "LGPL-3.0-or-later",
  },
  artifacts: {
    android: describe("android"),
    ios: describe("ios"),
  },
  source: describe("sources"),
};

writeFileSync(
  path.join(dist, "artifact-manifest.json"),
  `${JSON.stringify(manifest, null, 2)}\n`,
);
