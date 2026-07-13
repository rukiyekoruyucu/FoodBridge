// tests/unit/services/itemService.test.js
//
// Tests the itemService business logic layer using mocked repositories.
// No real DB connection — fully isolated unit tests.

jest.mock('../../../src/repositories/itemRepository');
jest.mock('../../../src/repositories/fridgeRepository');

const itemService    = require('../../../src/services/itemService');
const itemRepository = require('../../../src/repositories/itemRepository');
const fridgeRepository = require('../../../src/repositories/fridgeRepository');
const ApiError       = require('../../../src/utils/ApiError');

// ─── Helpers ───────────────────────────────────────────────────────────────
const makeFridge = (overrides = {}) => ({
  id: 1,
  owner_user_id: 42,
  name: 'My Fridge',
  is_public: 0,
  ...overrides,
});

const makeItem = (overrides = {}) => ({
  id: 10,
  fridge_id: 1,
  donor_user_id: 42,
  name: 'Elma',
  status: 'AVAILABLE',
  ...overrides,
});

// ─── createItemForFridge ────────────────────────────────────────────────────
describe('itemService.createItemForFridge()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('throws 404 when fridge not found', () => {
    fridgeRepository.getFridgeById.mockReturnValue(null);

    expect(() =>
      itemService.createItemForFridge({ fridgeId: 999, donorUserId: 1, name: 'X' })
    ).toThrow(new ApiError(404, 'Fridge not found'));
  });

  test('throws 403 when caller is not fridge owner', () => {
    fridgeRepository.getFridgeById.mockReturnValue(makeFridge({ owner_user_id: 99 }));

    expect(() =>
      itemService.createItemForFridge({ fridgeId: 1, donorUserId: 42, name: 'X' })
    ).toThrow(new ApiError(403, 'You are not the owner of this fridge'));
  });

  test('creates item when caller is owner', () => {
    const fridge = makeFridge({ owner_user_id: 42 });
    const created = makeItem();
    fridgeRepository.getFridgeById.mockReturnValue(fridge);
    itemRepository.createItem.mockReturnValue(created);

    const result = itemService.createItemForFridge({
      fridgeId: 1,
      donorUserId: 42,
      name: 'Elma',
    });

    expect(itemRepository.createItem).toHaveBeenCalledWith(
      expect.objectContaining({ fridgeId: 1, donorUserId: 42, name: 'Elma' })
    );
    expect(result).toEqual(created);
  });
});

// ─── updateMyItem ───────────────────────────────────────────────────────────
describe('itemService.updateMyItem()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('throws 404 when item not found or not owned', () => {
    itemRepository.updateItemById.mockReturnValue(null);

    expect(() =>
      itemService.updateMyItem({ id: 1, userId: 99, patch: { name: 'Yeni' } })
    ).toThrow(new ApiError(404, 'Item not found or not yours'));
  });

  test('returns updated item on success', () => {
    const updated = makeItem({ name: 'Yeni' });
    itemRepository.updateItemById.mockReturnValue(updated);

    const result = itemService.updateMyItem({ id: 10, userId: 42, patch: { name: 'Yeni' } });
    expect(result).toEqual(updated);
  });
});

// ─── removeMyItem ───────────────────────────────────────────────────────────
describe('itemService.removeMyItem()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('throws 404 when item not found or not owned', () => {
    itemRepository.removeItemById.mockReturnValue(null);

    expect(() =>
      itemService.removeMyItem(999, 42)
    ).toThrow(new ApiError(404, 'Item not found or not yours'));
  });

  test('returns removed item on success', () => {
    const removed = makeItem({ status: 'REMOVED' });
    itemRepository.removeItemById.mockReturnValue(removed);

    const result = itemService.removeMyItem(10, 42);
    expect(result).toEqual(removed);
  });
});

// ─── getLatestFeed ──────────────────────────────────────────────────────────
describe('itemService.getLatestFeed()', () => {
  beforeEach(() => jest.clearAllMocks());

  test('passes default params to repository', () => {
    itemRepository.listLatestFeed.mockReturnValue([]);
    itemService.getLatestFeed({});
    expect(itemRepository.listLatestFeed).toHaveBeenCalledWith({
      category: null,
      q: null,
      limit: 20,
      offset: 0,
    });
  });

  test('passes custom params through', () => {
    itemRepository.listLatestFeed.mockReturnValue([makeItem()]);
    const result = itemService.getLatestFeed({ category: 'food', q: 'elma', limit: 5, offset: 20 });
    expect(itemRepository.listLatestFeed).toHaveBeenCalledWith({
      category: 'food',
      q: 'elma',
      limit: 5,
      offset: 20,
    });
    expect(result).toHaveLength(1);
  });

  test('returns empty array when no items', () => {
    itemRepository.listLatestFeed.mockReturnValue([]);
    expect(itemService.getLatestFeed({})).toEqual([]);
  });
});

// ─── markItemExpired ────────────────────────────────────────────────────────
describe('itemService.markItemExpired()', () => {
  test('calls repository with EXPIRED status', () => {
    itemRepository.markItemStatus.mockReturnValue({ id: 5, status: 'EXPIRED' });
    itemService.markItemExpired(5);
    expect(itemRepository.markItemStatus).toHaveBeenCalledWith(5, 'EXPIRED');
  });
});
