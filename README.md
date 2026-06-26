# donuk/pgbouncer

A container for running PgBouncer, aimed at allowing full configuration via environment variables. This image wraps the official [percona/percona-pgbouncer](https://hub.docker.com/r/percona/percona-pgbouncer) image and adds support for dynamically setting the `listen_addr` and `listen_port` options through environment variables.

## Features

- **LISTEN_ADDR**: Set the `listen_addr` in `pgbouncer.ini` via the environment. Defaults to `0.0.0.0` if not specified.
- **LISTEN_PORT**: Set the `listen_port` in `pgbouncer.ini` via the environment. Defaults to `6432` if not specified.
- On container startup, the entrypoint script rewrites `pgbouncer.ini` to ensure these values are set according to the environment.

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

## How it Works

On startup, the image:

1. Reads your `/etc/pgbouncer/pgbouncer.ini`.
2. Removes any existing `listen_addr` or `listen_port` lines.
3. Inserts lines for `listen_addr` and `listen_port` under the `[pgbouncer]` section, using the environment or defaults.
4. Starts PgBouncer as normal.

All other configuration remains unchanged, so you can continue to mount your own `pgbouncer.ini` and other files as needed.

## Credits

- Based on [percona/percona-pgbouncer](https://hub.docker.com/r/percona/percona-pgbouncer).

## License

MIT or same as upstream image.
