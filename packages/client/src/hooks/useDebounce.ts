import { useState, useEffect } from 'react';


interface UseDebounceArgs {
  value: number;
  delay: number;
}

interface UseDebounceResult {
  debouncedValue: number;
}

export function useDebounce({ value, delay }: UseDebounceArgs): UseDebounceResult {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(
    () => {
      const handler = setTimeout(() => {
        setDebouncedValue(value);
      }, delay);

      return () => {
        clearTimeout(handler);
      };
    },
    [value, delay]
  );

  return { debouncedValue };
}