# Bundled dependencies

The release build statically links the following libraries into CPython and unpacks the listed universal wheels into `site-packages`. The build verifies every source archive and wheel before use and does not execute wheel build or installation code.

| Dependency | Version | Artifact digest | License | Purpose |
|---|---:|---|---|---|
| zlib | 1.3.2 | SHA-256 `bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16` | zlib | `zlib`, `gzip`, and ZIP/DEFLATE support |
| bzip2 | 1.0.8 | SHA-512 `083f5e675d73f3233c7930ebe20425a533feedeaaa9d8cc86831312a6581cefbe6ed0d08d2fa89be81082f2a5abdabca8b3c080bf97218a1bd59dc118a30b9f3` | bzip2 | `bz2` support |
| XZ Utils/liblzma | 5.8.3 | SHA-256 `fff1ffcf2b0da84d308a14de513a1aa23d4e9aa3464d17e64b9714bfdd0bbfb6` | 0BSD | `lzma` and XZ support |
| SQLite | 3.53.3 | SHA3-256 `98f2b3f3c11be6a03ea32346937b032c2472ebbd7a716bed36ca2f5693e7ce8b` | Public domain | `sqlite3` persistence within WASI preopens |
| tzdata | 2026.2 | SHA-256 `bbe9af844f658da81a5f95019480da3a89415801f6cc966806612cc7169bffe7` | Apache-2.0 | IANA time-zone fallback for `zoneinfo` |
| packaging | 26.2 | SHA-256 `5fc45236b9446107ff2415ce77c807cee2862cb6fac22b8a73826d0693b0980e` | Apache-2.0 OR BSD-2-Clause | Version, requirement, marker, and metadata parsing |
| python-dateutil | 2.9.0.post0 | SHA-256 `a8b2bc7bffae282281c8140a97d3aa9c14da0b136dfe83f850eea9a5f7470427` | BSD-3-Clause and Apache-2.0 | Date parsing, recurrence, and calendar arithmetic |
| six | 1.17.0 | SHA-256 `4721f391ed90541fddacab5acf947aa0d3dc7d27b2e1e8eda2be8970586c3274` | MIT | Required by python-dateutil |

SQLite uses its upstream Unix VFS. The runtime must expose the database directory through a writable WASI preopen. The build is single-threaded (`SQLITE_THREADSAFE=0`), matching the single-threaded CPython WASI runtime, and disables loadable SQLite extensions.
