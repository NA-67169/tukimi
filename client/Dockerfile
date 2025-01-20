FROM node:23.6.0

WORKDIR /home/node/app

COPY --chown=node:node package.json yarn.lock ./

USER node

RUN yarn install

COPY --chown=node:node . .

CMD ["yarn", "dev"]