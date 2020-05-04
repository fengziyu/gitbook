FROM nginx:alpine
EXPOSE 80
WORKDIR /
COPY _book /usr/share/nginx/html