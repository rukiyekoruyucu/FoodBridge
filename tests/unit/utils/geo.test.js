// tests/unit/utils/geo.test.js
const { distanceKm } = require('../../../src/utils/geo');

describe('geo.distanceKm()', () => {
  test('same point → 0 km', () => {
    expect(distanceKm(41.0, 28.9, 41.0, 28.9)).toBeCloseTo(0, 3);
  });

  test('Istanbul → Ankara ≈ 349 km', () => {
    // Istanbul: 41.0082, 28.9784 | Ankara: 39.9334, 32.8597
    const d = distanceKm(41.0082, 28.9784, 39.9334, 32.8597);
    expect(d).toBeGreaterThan(340);
    expect(d).toBeLessThan(360);
  });

  test('Istanbul → Izmir ≈ 328 km', () => {
    const d = distanceKm(41.0082, 28.9784, 38.4192, 27.1287);
    expect(d).toBeGreaterThan(310);
    expect(d).toBeLessThan(350);
  });

  test('symmetry: A→B equals B→A', () => {
    const d1 = distanceKm(41.0, 28.9, 39.9, 32.8);
    const d2 = distanceKm(39.9, 32.8, 41.0, 28.9);
    expect(d1).toBeCloseTo(d2, 6);
  });

  test('returns number', () => {
    expect(typeof distanceKm(0, 0, 1, 1)).toBe('number');
  });

  test('short distance (1 km apart) is positive and < 2', () => {
    // roughly 1 degree lat = ~111 km → 0.01 deg ≈ 1.1 km
    const d = distanceKm(41.0, 28.9, 41.01, 28.9);
    expect(d).toBeGreaterThan(0);
    expect(d).toBeLessThan(2);
  });
});
