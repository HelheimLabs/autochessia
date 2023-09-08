FROM node:18

## install pnpm
RUN npm install -g pnpm

## install golang and protobuf
RUN apt update && apt install golang protobuf-compiler curl -y

WORKDIR /app

## clone mud repo and lock hash
RUN git clone https://github.com/latticexyz/mud.git && \
    cd mud && \
    git checkout 57ee7f9cb7b5803a6f6b6ad69a7d50fbef4d8dc1 && \
    pnpm install && \
    ## source forge PATH here
    . /root/.bashrc && \
    pnpm build

WORKDIR /app/mud/packages/store-indexer

## edit listen host
RUN sed -i "s/await server.listen({ port: env.PORT });/await server.listen({ host: '0.0.0.0', port: env.PORT });/g" bin/sqlite-indexer.ts


# RUN pnpm build

ENTRYPOINT [ "pnpm" , "start" ]