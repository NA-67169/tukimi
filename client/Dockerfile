FROM node:22.12.0 AS builder

WORKDIR /client

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN npm run build

FROM node:22.12.0-slim AS development

WORKDIR /client

COPY package.json package-lock.json ./
RUN npm ci --production

COPY --from=builder /app/public ./public
COPY --from=builder /app/src ./src

EXPOSE 3000

CMD ["npm", "start"]

FROM nginx:alpine AS production

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]