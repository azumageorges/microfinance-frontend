# ==========================================
# Étape 1 : Build Flutter Web
# ==========================================

FROM ubuntu:22.04 AS build-env


ENV DEBIAN_FRONTEND=noninteractive

ENV FLUTTER_HOME=/opt/flutter

ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Empêche les erreurs de permissions lors de l'extraction tar
ENV TAR_OPTIONS="--no-same-owner"



# ==========================================
# Installation des dépendances nécessaires
# ==========================================

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*



# ==========================================
# Installation Flutter 3.44.7
# (Dart 3.12.2 compatible avec sdk ^3.12.2)
# ==========================================

RUN git clone https://github.com/flutter/flutter.git \
    -b 3.44.7 \
    --depth 1 \
    ${FLUTTER_HOME}



# Autoriser Flutter dans Docker
RUN git config --global --add safe.directory ${FLUTTER_HOME}



# Vérification version Flutter/Dart
RUN flutter --version



# ==========================================
# Préparation du projet
# ==========================================

WORKDIR /app



# Copie des fichiers de dépendances
COPY pubspec.yaml pubspec.lock ./



# Activation Flutter Web
RUN flutter config --enable-web



# Préchargement des composants Web
RUN flutter precache --web



# Installation des dépendances
RUN flutter pub get --verbose



# Copie du reste du projet
COPY . .



# ==========================================
# Compilation Flutter Web
# ==========================================

RUN flutter build web \
    --release \
    --dart-define=API_BASE_URL=https://microfinance-backend-etz5.onrender.com





# ==========================================
# Étape 2 : Serveur Nginx Production
# ==========================================

FROM nginx:alpine



# Configuration SPA Flutter
COPY nginx.conf /etc/nginx/conf.d/default.conf



# Copie du build Flutter
COPY --from=build-env \
    /app/build/web \
    /usr/share/nginx/html



EXPOSE 80



CMD ["nginx", "-g", "daemon off;"]