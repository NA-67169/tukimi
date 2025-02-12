FROM node:22.12.0

USER node
WORKDIR /home/node/app

RUN mkdir node_modules

CMD ["/bin/bash", "-c", "yarn install && yarn dev"]