const donationService = require("../services/donationService");

async function requestDonation(req, res, next) {
  try {
    const { itemId, type } = req.body;

    const donation = await donationService.requestDonation({
      itemId,
      requesterId: req.user.id,
      type: type || "DONATION"
    });

    res.status(201).json(donation);
  } catch (err) {
    next(err);
  }
}

async function listItemRequests(req, res, next) {
  try {
    const itemId = parseInt(req.params.itemId, 10);
    const list = await donationService.listItemRequests(itemId, req.user.id);
    res.json(list);
  } catch (err) {
    next(err);
  }
}

async function acceptRequest(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const updated = await donationService.acceptRequest(id, req.user.id);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function confirmPickup(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const updated = await donationService.confirmPickup(id, req.user.id);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function listMyDonations(req, res, next) {
  try {
    const list = await donationService.listUserDonations(req.user.id);
    res.json(list);
  } catch (err) {
    next(err);
  }
}
async function rejectRequest(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const reason = req.body?.reason ?? null;
    const updated = await donationService.rejectRequest(id, req.user.id, reason);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}


module.exports = {
  requestDonation,
  listItemRequests,
  acceptRequest,
  confirmPickup,
  listMyDonations,
  rejectRequest
};
