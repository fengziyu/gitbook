FROM node as build
WORKDIR /app
COPY package.json yarn.lock /app/
RUN yarn
COPY . .
RUN yarn build

FROM nginx:alpine
EXPOSE 80
WORKDIR /
COPY --from=build /app/_book /usr/share/nginx/html