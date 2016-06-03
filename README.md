README
------

A (simplistic, coffeescript, docker, rabbitmq, amqp, promise)-based
push notification micrservice for ios and android applications.


Run the service using docker
----------------------------

		docker build . -name push-notification-service
		docker run -it --rm=true \
			-v push-notification-service-data:/data \
			-e CERTS_PATH=/data \
			-e GOOGLE_API_KEY="your-google-gcm-api-key" \
			-e NODE_ENV=development

Look at `push-notification-service-data/` to understand how to place your
certificates.


Using the service
-----------------

In your backend or application instances you can send messages to rabbitmq using
the great [amqp-as-promised](https://github.com/ttab/amqp-as-promised) RPC package

Messages will be queued by rabbitmq and sent one by one. You can launch many
instances of this micro-service to increase delivery throughput
(if you really need to..)

See `client_example.coffee` for a code example.
