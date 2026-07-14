const cloudinary = require("../config/cloudinary");
const ApiError = require("../utils/ApiError");

async function uploadImage(req, res, next) {
  try {
    let file = req.file;
    if (!file && req.files) {
      if (req.files.image) file = req.files.image[0];
      else if (req.files.file) file = req.files.file[0];
    }
    if (!file) throw new ApiError(400, "image file is required");

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
      stream.end(file.buffer);
    });

    return res.json({
      url: result.secure_url,
      secure_url: result.secure_url,
      imageUrl: result.secure_url,
      publicId: result.public_id,
    });
  } catch (e) {
    next(e);
  }
}

module.exports = { uploadImage };
