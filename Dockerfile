FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY signaling-server ./signaling-server

ENV NODE_ENV=production
ENV DATA_DIR=/web

CMD ["npm", "start"]