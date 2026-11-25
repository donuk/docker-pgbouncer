# donuk/pgbouncer

A container for running PgBouncer, aimed at allowing full configuration via environment variables. This image wraps the official [percona/percona-pgbouncer](https://hub.docker.com/r/percona/percona-pgbouncer) image and lets you set any `[pgbouncer]` option in `pgbouncer.ini` through environment variables.

## Features

- **PGBOUNCER_&lt;OPTION&gt;**: Any `[pgbouncer]` option can be set by upper-casing its name and prefixing it with `PGBOUNCER_`. For example `PGBOUNCER_POOL_MODE=transaction` sets `pool_mode = transaction`.
- **LISTEN_ADDR** / **LISTEN_PORT**: Shorthand for `listen_addr` and `listen_port`, defaulting to `0.0.0.0` and `6432`. `PGBOUNCER_LISTEN_ADDR` / `PGBOUNCER_LISTEN_PORT` take precedence if both are set.
- On container startup, the entrypoint script rewrites `pgbouncer.ini` so these values match the environment. Environment variables win over any existing definition of the same option in the file.

## Usage

Run the container as you would the original image, but you can now override the listening address and port entirely via environment variables:

```sh
docker run -e LISTEN_ADDR=0.0.0.0 -e LISTEN_PORT=6543 \
  -v /your/pgbouncer.ini:/etc/pgbouncer/pgbouncer.ini \
  -p 6543:6543 \
  donuk/pgbouncer
```

## Environment Variables

- `LISTEN_ADDR` (optional): The bind address for PgBouncer (`listen_addr`). Default: `0.0.0.0`.
- `LISTEN_PORT` (optional): The port for PgBouncer (`listen_port`). Default: `6432`.
- `PGBOUNCER_<OPTION>` (optional): Any other `[pgbouncer]` option, e.g. `PGBOUNCER_MAX_CLIENT_CONN=500`. See the [PgBouncer config reference](https://www.pgbouncer.org/config.html) for the available options.

The names `PGBOUNCER_PORT`, `PGBOUNCER_PORT_*`, `PGBOUNCER_SERVICE_HOST` and `PGBOUNCER_SERVICE_PORT*` are ignored, because Kubernetes injects them for a Service called `pgbouncer`. Use `LISTEN_PORT` or `PGBOUNCER_LISTEN_PORT` to set the port.

The upstream image's own `AUTH_TYPE` variable still works. `PGBOUNCER_AUTH_TYPE` overrides it if both are set.

## Reducing load on the backend server

Postgres memory use is driven mainly by the number of server connections, so the useful options are those that cap or recycle them:

```sh
docker run \
  -e PGBOUNCER_POOL_MODE=transaction \
  -e PGBOUNCER_DEFAULT_POOL_SIZE=10 \
  -e PGBOUNCER_MAX_DB_CONNECTIONS=20 \
  -e PGBOUNCER_RESERVE_POOL_SIZE=0 \
  -e PGBOUNCER_SERVER_IDLE_TIMEOUT=60 \
  -e PGBOUNCER_SERVER_LIFETIME=1800 \
  -e PGBOUNCER_QUERY_WAIT_TIMEOUT=30 \
  donuk/pgbouncer
```

| Option | Effect |
|---|---|
| `PGBOUNCER_POOL_MODE` | `transaction` lets many clients share a few server connections. |
| `PGBOUNCER_DEFAULT_POOL_SIZE` | Server connections per user/database pair. |
| `PGBOUNCER_MAX_DB_CONNECTIONS` | Hard cap on server connections per database. |
| `PGBOUNCER_MAX_USER_CONNECTIONS` | Hard cap on server connections per user. |
| `PGBOUNCER_RESERVE_POOL_SIZE` | Extra burst connections; `0` keeps memory predictable. |
| `PGBOUNCER_SERVER_IDLE_TIMEOUT` | Close idle server connections sooner. |
| `PGBOUNCER_SERVER_LIFETIME` | Recycle long-lived backends, whose caches grow over time. |
| `PGBOUNCER_MAX_PREPARED_STATEMENTS` | Limits prepared statements tracked in transaction mode. |
| `PGBOUNCER_MAX_CLIENT_CONN` | Limits clients connecting to PgBouncer itself. |
| `PGBOUNCER_QUERY_WAIT_TIMEOUT` | Fail clients that wait too long for a connection instead of queueing forever. |
| `PGBOUNCER_QUERY_TIMEOUT` / `PGBOUNCER_IDLE_TRANSACTION_TIMEOUT` | Stop long or stuck work from holding backends. |

Per-database settings such as `pool_size` live in the `[databases]` section, which is not touched by this image. Set them in your mounted `pgbouncer.ini`.

## How it Works

On startup, the image:

1. Collects `LISTEN_ADDR`, `LISTEN_PORT` and every `PGBOUNCER_<OPTION>` variable. Option names are lower-cased.
2. Reads your `/etc/pgbouncer/pgbouncer.ini`.
3. Removes any existing definition of those options from the `[pgbouncer]` section.
4. Inserts the new values directly under `[pgbouncer]`, adding the section if it is missing.
5. Starts PgBouncer as normal.

All other configuration remains unchanged, so you can continue to mount your own `pgbouncer.ini` and other files as needed. The file is rewritten in place, so mount it so that it is writable and replaceable (for example, mount a directory rather than a single file).

## Credits

- Based on [percona/percona-pgbouncer](https://hub.docker.com/r/percona/percona-pgbouncer).

## License

MIT or same as upstream image.
