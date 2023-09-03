function decodeHero(hero: number) {
  const tier = (hero >> 8)+1; 
  const internalIndex = hero & 0xFF;
  return [tier, internalIndex, hero];
}

function encodeHero(tier: number, internalIndex: number): number{
  return ((tier-1) << 8) + internalIndex;
}

function padAddress(address: string) {
  address = address.toLowerCase();
  if(!address.startsWith('0x')) {
    address = '0x' + address;
  }

  return '0x' + address.slice(2).padStart(64, '0'); 
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

function generateColor(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash += str.charCodeAt(i);
  }

  const red = (hash & 0xff0000) >> 16;
  const green = (hash & 0x00ff00) >> 8;
  const blue = hash & 0x0000ff;

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

  ctx.fillStyle = generateColor(address);
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
  encodeHero,
  convertToPos,
  convertToIndex,
  padAddress,
  shortenAddress,
  generateAvatar,
};
