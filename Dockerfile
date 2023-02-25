FROM debian:bullseye-slim as prepare

RUN apt update &&\
    apt install -y tini


FROM node:18-alpine as prod-deps
# Create workdir
WORKDIR /workspace
# Install prod deps
COPY package.json package-lock.json .
RUN npm install --omit=dev


FROM prod-deps as dev-deps
# Install all deps
RUN npm install


FROM dev-deps as build
# Copy source
COPY . .
# Build server
RUN npm run build


FROM gcr.io/distroless/nodejs:18 as prod
# Create workid
WORKDIR /workspace
# COPY dependencies
COPY --from=prod-deps /workspace/node_modules ./node_modules
# COPY server
COPY --from=build /workspace/dist/server/ .
# Refer to https://github.com/GoogleContainerTools/distroless/issues/550
COPY --from=prepare /usr/bin/tini-static /tini
ENTRYPOINT ["/tini", "-s", "--", "/nodejs/bin/node"]
CMD ["mongodb-proxy.js"]
