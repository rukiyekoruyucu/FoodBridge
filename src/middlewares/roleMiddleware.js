const ApiError = require("../utils/ApiError");

function roleMiddleware(allowedRoles = []) {
  return (req, res, next) => {
    if (!req.user) {
      return next(new ApiError(401, "Not authenticated"));
    }
    if (!allowedRoles.includes(req.user.role)) {
      return next(new ApiError(403, "Not authorized"));
    }
    next();
  };
}

module.exports = roleMiddleware;
