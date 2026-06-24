const cloudinary = require("../config/cloudinary");
const ApiError = require("../utils/ApiError");

async function uploadImage(req, res, next) {
  try {
    if (!req.file) throw new ApiError(400, "image file is required");

    // Folder: avatars | items-public | items-private
    const folder = (req.query.folder || "misc").toString();

    const result = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: `foodbridge/${folder}`,
          resource_type: "image",
        },
        (err, uploaded) => {
          if (err) return reject(err);
          resolve(uploaded);
        }
      );
      stream.end(req.file.buffer);
    });

    return res.json({
      imageUrl: result.secure_url,
      publicId: result.public_id,
    });
  } catch (e) {
    next(e);
  }
}

module.exports = { uploadImage };
