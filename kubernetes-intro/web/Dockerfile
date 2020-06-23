FROM node:lts-slim AS builder
WORKDIR /server
COPY ./package.json /yarn.lock ./
RUN yarn install
COPY ./src ./

FROM node:lts-slim

RUN groupadd -g 1001 appuser && \
    useradd -r -u 1001 -g appuser appuser && \
    mkdir /app && \
    chown appuser:appuser /app && \
    chmod 555 /app

WORKDIR /server
COPY --chown=appuser:appuser --from=builder /server .
RUN find . -type d -exec chmod 555 {} \; && \
    find . -type f -exec chmod 444 {} \;

USER appuser

CMD ["node", "index.js"]
