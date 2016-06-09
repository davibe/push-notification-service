FROM node:5

# prepare env
ENV NODE_PATH /usr/local/lib/node_modules
ENV PATH=$PATH:/node_modules/.bin
ENV JOBS 4
RUN npm set progress=false
RUN npm install -g coffee-script

ADD ./package.json /push-notification-service/
WORKDIR /push-notification-service
RUN npm install .
ADD . /push-notification-service
