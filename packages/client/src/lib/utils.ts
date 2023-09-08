import { Entity } from "@latticexyz/recs";
import { encodeEntity } from "@latticexyz/store-sync/recs";
import { Hex, numberToHex } from "viem";

// encodedCreatureCount is 5 8bit
export function decodeHeroCount(encodedCreatureCount: bigint) {
  const legendCount = encodedCreatureCount >> 32n;
  const epicCount = (encodedCreatureCount >> 24n) & 0xFFn;
  const rareCount =  (encodedCreatureCount >> 16n) & 0xFFn ;
  const uncommonCount = (encodedCreatureCount >> 8n) & 0xFFn;
  const commonCount = (encodedCreatureCount) & 0xFFn;

  const totalCount = legendCount +epicCount + rareCount+uncommonCount +commonCount;

  return {totalCount, legendCount, epicCount,rareCount,uncommonCount,commonCount}
}

export function encodeHeroId(rarity: bigint, internalIndex: bigint): bigint {
  return (rarity << 8n) + internalIndex;
}

export function encodeHeroIdString(rarity: bigint, internalIndex: bigint): Hex {
  return numberToHex((rarity << 8n) + internalIndex,{size: 2})
}


export function encodeCreatureEntity(creatureId: bigint | number): Entity {
  if (typeof creatureId === "number") {
    creatureId = BigInt(creatureId)
  }

  return encodeEntity({id: "bytes32"},{id: numberToHex(creatureId,{size:32})})
}


export function numberArrayToBigIntArray(array: (number | bigint)[] | undefined): bigint[] {
  if (!array) {
    return []
  }

  array.forEach((v,i)=>{
    array[i] = BigInt(v)
  })

  return array as bigint[];
}

function decodeHero(creatureId: bigint | number) {
  if (typeof creatureId === "number") {
    creatureId = BigInt(creatureId)
  }

  const tier = ((creatureId >> 16n)&0xFFn)+1n; 
  const rarity = (creatureId>> 8n) & 0xFFn;
  const internalIndex = creatureId & 0xFFn;
  const heroId = encodeHeroId(rarity,internalIndex)
  const heroIdString = encodeHeroIdString(rarity,internalIndex);
  return {tier, rarity,internalIndex, heroId,heroIdString,creatureId};
}


function encodeHero(tier: bigint,heroId: bigint): bigint{
  return ((tier-1n) << 16n) + heroId;
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


function shallowEqual(obj1: { [x: string]: any; } | null, obj2: { [x: string]: any; } | null) {
  if (obj1 === obj2) {
    return true;
  }
  
  if (typeof obj1 !== 'object' || obj1 === null || 
      typeof obj2 !== 'object' || obj2 === null) {
    return false;
  }
    
  let keys1 = Object.keys(obj1);
  let keys2 = Object.keys(obj2);

  if (keys1.length !== keys2.length) {
    return false;
  }

  for (let key in obj1) {
    if (obj1[key] !== obj2[key]) {
      return false;
    }
  }

  return true;
}

 

export {
  decodeHero,
  encodeHero,
  convertToPos,
  convertToIndex,
  padAddress,
  shortenAddress,
  generateAvatar,
  shallowEqual
};
