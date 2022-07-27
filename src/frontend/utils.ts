// Results
export function fromOk(result): any {
  // get the value from an ok result
  return result.ok;
}

export function fromErr(result): any {
  // get the err from an error result
  return Object.keys(result.err)[0];
}

export function isOk(result): boolean {
  if (result) {
    if ("ok" in result) {
      return true;
    }
  }
  return false;
}

export function isErr(result): boolean {
  if (result) {
    if ("err" in result) {
      return true;
    }
  }
  return false;
}

export function fromVariantToString(v): string {
  // A Motoko variant is stored in javascript as an
  // object with a single property eg {"system": null}
  return Object.keys(v)[0];
}

export function getVariantValue(v): any {
  // A Motoko variant can be stored with a value, represented in javascript as an
  // object with a single property eg {"system": possiblevalue }
  // return the possible value
  return Object.values(v)[0];
}

export const toNullable = <T>(value?: T): [] | [T] => {
  return value ? [value] : [];
};

export const fromNullable = <T>(value: [] | [T]): T | undefined => {
  return value?.[0];
};

export type Time = bigint;

export const fromTimestamp = (value: Time): Date => {
  return new Date(Number(value) / 1000000);
};

export const toTimestamp = (value: Date): Time => {
  return BigInt(value.getTime());
};
