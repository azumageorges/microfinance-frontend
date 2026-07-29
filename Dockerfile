# Étape 1 : Compilation Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY . .

RUN flutter pub get

RUN flutter build web \
    --release \
    --dart-define=API_BASE_URL=https://microfinance-backend-etz5.onrender.com

# Étape 2 : Serveur Web Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]