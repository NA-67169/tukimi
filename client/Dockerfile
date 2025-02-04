FROM node:23.6.0

WORKDIR /client

RUN chown -R node:node /client

USER node

COPY --chown=node:node package.json ./

RUN yarn install

COPY --chown=node:node . .

CMD ["yarn", "dev"]