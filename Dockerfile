# ==========================================
# Étape 1 : Build Flutter Web
# ==========================================

FROM ubuntu:22.04 AS build-env


ENV DEBIAN_FRONTEND=noninteractive

ENV FLUTTER_HOME=/opt/flutter

ENV PATH="${FLUTTER_HOME}/bin:${PATH}"


# Dépendances nécessaires Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*



# Installation Flutter version fixe
RUN git clone https://github.com/flutter/flutter.git \
    -b 3.44.7 \
    --depth 1 \
    ${FLUTTER_HOME}



# Autoriser Flutter dans Docker
RUN git config --global --add safe.directory ${FLUTTER_HOME}



# Vérification Flutter/Dart
RUN flutter --version



WORKDIR /app



# Cache des dépendances
COPY pubspec.yaml pubspec.lock ./


RUN flutter config --enable-web


RUN flutter pub get



# Copie du projet
COPY . .



# Compilation Flutter Web
RUN flutter build web \
    --release \
    --dart-define=API_BASE_URL=https://microfinance-backend-etz5.onrender.com




# ==========================================
# Étape 2 : Serveur Nginx
# ==========================================

FROM nginx:alpine



COPY nginx.conf /etc/nginx/conf.d/default.conf



COPY --from=build-env \
    /app/build/web \
    /usr/share/nginx/html



EXPOSE 80



CMD ["nginx", "-g", "daemon off;"]