const ApiError = require("../utils/ApiError");

function validate(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      return next(
        new ApiError(400, "Validation error", error.details.map((d) => d.message))
      );
    }

    req.body = value;
    next();
  };
}

module.exports = validate;
