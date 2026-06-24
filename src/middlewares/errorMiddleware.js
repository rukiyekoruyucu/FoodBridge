const ApiError = require("../utils/ApiError");
const logger = require("../utils/logger");

function notFoundHandler(req, res, next) {
  next(new ApiError(404, `Route ${req.originalUrl} not found`));
}

function errorHandler(err, req, res, next) {
  logger.error(err);

  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      message: err.message,
      details: err.details || undefined
    });
  }

  return res.status(500).json({
    message: "Internal server error"
  });
}

module.exports = {
  notFoundHandler,
  errorHandler
};
