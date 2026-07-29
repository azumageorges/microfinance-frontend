FROM ghcr.io/cirruslabs/flutter:3.32.8

WORKDIR /app

COPY . .

RUN flutter pub get

RUN flutter build web --release