README
------

A (simplistic, coffeescript, docker, rabbitmq, amqp, promise)-based
push notification micrservice for ios and android applications.


Run the service using docker
----------------------------

    docker build -t push-notification-service .
    docker run -it --rm=true \
      -v push-notification-service-data:/data \
      -e CERTS_PATH=/data \
      -e RABBITMQ_URL="amqp://localhost:5672//?heartbeat=10" \
      -e GOOGLE_API_KEY="your-google-gcm-api-key" \
      -e NODE_ENV=development \
      push-notification-service coffee src/service.coffee

Look at `push-notification-service-data/` to understand how to place your
certificates. I mount a separate container volume to keep them private.


Run tests
---------

Continuous integration style

    docker-compose build
    docker-compose run test
    docker-compose stop -t1
    docker-compose rm -f


Using the service
-----------------

In your backend or application instances you can send messages to rabbitmq using
the great [amqp-as-promised](https://github.com/ttab/amqp-as-promised) RPC package

Messages will be queued by rabbitmq and sent one by one. You can launch many
instances of this micro-service to increase delivery throughput
(if you really need to..)

See `client_example.coffee` for a code example.
