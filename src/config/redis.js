const { createClient } = require("redis");
const config = require("./index");
const logger = require("../utils/logger");

const client = createClient({
  url: config.redisUrl
});

client.on("error", (err) => logger.error("Redis Client Error", err));

async function connectRedis() {
  if (!config.redisUrl) {
    logger.info("Redis disabled (no REDIS_URL)");
    return;
  }
  if (!client.isOpen) {
    await client.connect();
    logger.info("Redis connected");
  }

  }


module.exports = {
  client,
  redis: client,
  connectRedis
};
