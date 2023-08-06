function decodeHero(hero: any) {
  const creatureId = Number(BigInt(hero >> 32n));
  const tier = Number(BigInt(hero & ((1n << 32n) - 1n)));

  return [creatureId, tier, hero];
}

function convertToPos(index: number) {
  if (index < 0 || index > 63) {
    // throw new Error('Out of range');
  }
  const x = index % 8;
  const y = (index - x) / 8;
  return [x, y];
}

function convertToIndex(x: number, y: number): number {
  if (x < 0 || x > 7 || y < 0 || y > 7) {
    // throw new Error('Out of range');
  }
  return y * 8 + x;
}

function shortenAddress(address: string) {
  if (!address) {
    return "";
  }

  const firstPart = address.substring(0, 6);
  const lastPart = address.substring(address.length - 4);

  return `${firstPart}.....${lastPart}`;
}

function generateColor(): string {
  const red = Math.floor(Math.random() * 200);
  const green = Math.floor(Math.random() * 200);
  const blue = Math.floor(Math.random() * 200);

  return `rgb(${red}, ${green}, ${blue})`;
}

function generateAvatar(address: string): string {
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d");

  canvas.width = 200;
  canvas.height = 200;

  if (!ctx) {
    throw new Error("Failed to get canvas context");
  }

  ctx.fillStyle = generateColor();
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.fillStyle = "#fff";
  ctx.font = "bold 48px Arial";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(address.slice(0, 6), 100, 100);

  return canvas.toDataURL();
}

export {
  decodeHero,
  convertToPos,
  convertToIndex,
  shortenAddress,
  generateAvatar,
};
