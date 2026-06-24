const http = require("http");
const app = require("./app");
const config = require("./config");
const logger = require("./utils/logger");
const initSocket = require("./sockets/socketHandler");

const server = http.createServer(app);

initSocket(server);

server.listen(config.port, "0.0.0.0", () => {
  logger.info(`Server running on port ${config.port}`);
});
