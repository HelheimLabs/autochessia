function decodeHero(hero) {
  const creatureId = Number(BigInt(hero >> 32n));
  const tier = Number(BigInt(hero & ((1n << 32n) - 1n)));

  return [creatureId, tier];
}

function convertToPos(index: number) {
  if (index < 0 || index > 63) {
    // throw new Error('Out of range');
  }
  const x = index % 8; 
  const y = (index - x) / 8; 
  return [x, y] 
}

function convertToIndex(x: number, y: number): number {
  if (x < 0 || x > 7 || y < 0 || y > 7) {
    // throw new Error('Out of range');
  }
  return y * 8 + x;
}

export {
  decodeHero,
  convertToPos,
  convertToIndex
}