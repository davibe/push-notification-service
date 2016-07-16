For APN service we create `cert.pem` and `key.pem` files as explained here
[these instructions](https://github.com/argon/node-apn/wiki/Preparing-Certificates)

Place cert.pem and key.pem in `development/` and/or `production/` subdirs of `$CERT_PATHS/apn`
i.e. $CERT_PATHS/apn/development/key.p12

The service will use `production/*` if NODE_ENV env var is set to 'production'
or `development/*` otherwise
