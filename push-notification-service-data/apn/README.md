For APN service we create a `key.p12` file as explained here
[these instructions](https://github.com/argon/node-apn/wiki/Preparing-Certificates)

Place key.p12 in `development/` and/or `production/` subdirs of `$CERT_PATHS/apn`
i.e. $CERT_PATHS/apn/development/key.p12

The service will use `production/*` if NODE_ENV env var is set to 'production'
or `development/*` otherwise
