// tests/unit/services/donationService.test.js
//
// Unit tests for donation business logic.
// All DB and external dependencies are mocked.

jest.mock('../../../src/repositories/donationRepository');
jest.mock('../../../src/repositories/itemRepository');
jest.mock('../../../src/repositories/chatRepository');
jest.mock('../../../src/services/kindnessService');
jest.mock('../../../src/config/db');

const donationService    = require('../../../src/services/donationService');
const donationRepository = require('../../../src/repositories/donationRepository');
const itemRepository     = require('../../../src/repositories/itemRepository');
const ApiError           = require('../../../src/utils/ApiError');

// ─── Helpers ───────────────────────────────────────────────────────────────
const makeItem = (overrides = {}) => ({
  id: 10,
  donor_user_id: 42,
  status: 'AVAILABLE',
  ...overrides,
});

const makeDonation = (overrides = {}) => ({
  id: 1,
  item_id: 10,
  donor_id: 42,
  recipient_id: 7,
  status: 'PENDING',
  type: 'DONATION',
  ...overrides,
});

// ─── requestDonation ────────────────────────────────────────────────────────
describe('donationService.requestDonation()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('throws 404 when item not found', () => {
    itemRepository.getItemById.mockReturnValue(null);

    expect(() =>
      donationService.requestDonation({ itemId: 999, requesterId: 7 })
    ).toThrow(new ApiError(404, 'Item not found'));
  });

  test('throws 400 when item is not AVAILABLE', () => {
    itemRepository.getItemById.mockReturnValue(makeItem({ status: 'RESERVED' }));

    expect(() =>
      donationService.requestDonation({ itemId: 10, requesterId: 7 })
    ).toThrow(new ApiError(400, 'Item is not available'));
  });

  test('throws 400 when owner requests own item', () => {
    itemRepository.getItemById.mockReturnValue(makeItem({ donor_user_id: 42 }));

    expect(() =>
      donationService.requestDonation({ itemId: 10, requesterId: 42 })
    ).toThrow(new ApiError(400, 'Owner cannot request own item'));
  });

  test('throws 409 when duplicate request exists', () => {
    itemRepository.getItemById.mockReturnValue(makeItem());
    donationRepository.findActiveByItemAndRecipient.mockReturnValue(makeDonation());

    expect(() =>
      donationService.requestDonation({ itemId: 10, requesterId: 7 })
    ).toThrow(new ApiError(409, 'You already requested this item'));
  });

  test('creates donation when all checks pass', () => {
    itemRepository.getItemById.mockReturnValue(makeItem());
    donationRepository.findActiveByItemAndRecipient.mockReturnValue(null);
    donationRepository.createDonation.mockReturnValue(makeDonation());

    const result = donationService.requestDonation({ itemId: 10, requesterId: 7 });

    expect(donationRepository.createDonation).toHaveBeenCalledWith({
      itemId: 10,
      donorId: 42,      // donor_user_id from the item
      recipientId: 7,
      type: 'DONATION',
    });
    expect(result).toMatchObject({ status: 'PENDING', item_id: 10 });
  });
});

// ─── listItemRequests ────────────────────────────────────────────────────────
describe('donationService.listItemRequests()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('throws 404 when item not found', () => {
    itemRepository.getItemById.mockReturnValue(null);
    expect(() => donationService.listItemRequests(999, 42)).toThrow(
      new ApiError(404, 'Item not found')
    );
  });

  test('throws 403 when caller is not item owner', () => {
    itemRepository.getItemById.mockReturnValue(makeItem({ donor_user_id: 99 }));
    expect(() => donationService.listItemRequests(10, 42)).toThrow(
      new ApiError(403, 'Not item owner')
    );
  });

  test('returns pending requests for owner', () => {
    itemRepository.getItemById.mockReturnValue(makeItem({ donor_user_id: 42 }));
    donationRepository.listPendingRequestsByItem.mockReturnValue([makeDonation()]);

    const result = donationService.listItemRequests(10, 42);
    expect(result).toHaveLength(1);
    expect(result[0].status).toBe('PENDING');
  });
});
