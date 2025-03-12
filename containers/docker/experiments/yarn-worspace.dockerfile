FROM node:18-alpine AS builder

WORKDIR /app
COPY . .

RUN yarn install --frozen-lockfile

WORKDIR /app
RUN yarn build:client

FROM nginx:alpine AS runner
COPY --from=builder /app/packages/client/dist /usr/share/nginx/html/[path]

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]