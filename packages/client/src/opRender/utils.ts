export function addElementToArray(
  array: number[],
  data: number,
  index: number
): number[] {
  return array.map((v, i) => {
    if (Number(i) === Number(index)) {
      return data;
    }
    return v;
  });
}

export function popArrayByIndex<T>(array: T[], index: number): T[] {
  const lastValue = array[array.length - 1];
  // swap lastValue with popped value
  array[index] = lastValue;

  // remove new last value
  array.pop();

  return array;
}

export function removeElementByIndex(array: number[], index: number): number[] {
  return array.map((v, i) => {
    if (i === index) {
      return 0;
    }
    return v;
  });
}

export function pushToArray<T>(array: T[], value: T): T[] {
  return [...array, value];
}

export function popArrayByIndexes<T>(array: T[], indexes: number[]): T[] {
  const lastValues = [];

  // get last n values
  for (const index of indexes) {
    lastValues.push(array[index]);
  }

  // swap the indexed n with last n

  for (const order in indexes) {
    const index = indexes[order];
    array[index] = lastValues[order];
  }

  // pop count as the same as indexes length
  indexes.forEach(() => {
    array.pop();
  });

  return array;
}
