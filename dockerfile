ARG NODE_VERSION=22.19.0

# 1. Verwende einen Builder-Container
FROM node:${NODE_VERSION}-alpine as builder

# Installiere notwendige Abhängigkeiten
RUN apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig && \
    update-ms-fonts && \
    fc-cache -f && \
    apk del fonts && \
    find /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \;

# Installiere git und weitere Abhängigkeiten
RUN apk add --update git openssh graphicsmagick tini tzdata ca-certificates libc6-compat jq

# Installiere n8n und npm-Abhängigkeiten
COPY .npmrc /usr/local/etc/npmrc
RUN npm install -g npm@9.9.2 full-icu@1.5.0
RUN npm install -g n8n   # 🚀 HIER WIRD n8n INSTALLIERT

# Aktiviert corepack, installiert pnpm
WORKDIR /tmp
COPY package.json ./
RUN corepack enable && corepack prepare --activate

# Aufräumen
RUN rm -rf /lib/apk/db /var/cache/apk/ /tmp/* /root/.npm /root/.cache/node /opt/yarn*

# 2. Kopiere die Dateien in ein neues Image
FROM node:${NODE_VERSION}-alpine

# Kopiere die installierten Abhängigkeiten
COPY --from=builder / /

# Lösche den Cache für ältere NodeJS-Versionen
RUN rm -rf /tmp/v8-compile-cache*

# Setze das Arbeitsverzeichnis
WORKDIR /home/node
ENV NODE_ICU_DATA /usr/local/lib/node_modules/full-icu

# Exponiere den Port für n8n
EXPOSE 5678/tcp

# Starte n8n als Standardprozess
CMD ["n8n"]
