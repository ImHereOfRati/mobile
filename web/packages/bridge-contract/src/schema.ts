export type JsonPrimitive = boolean | number | string | null;
export type JsonValue =
  JsonPrimitive | { [key: string]: JsonValue } | JsonValue[];

export interface StringSchema {
  kind: "string";
}

export interface IntegerSchema {
  kind: "integer";
}

export interface NumberSchema {
  kind: "number";
}

export interface BooleanSchema {
  kind: "boolean";
}

export interface JsonSchema {
  kind: "json";
}

export interface EnumSchema<
  Name extends string = string,
  Values extends readonly string[] = readonly string[],
> {
  kind: "enum";
  name: Name;
  values: Values;
}

export interface ArraySchema<Item extends Schema = Schema> {
  kind: "array";
  item: Item;
}

export interface NullableSchema<Value extends Schema = Schema> {
  kind: "nullable";
  value: Value;
}

export interface OptionalSchema<Value extends Schema = Schema> {
  kind: "optional";
  value: Value;
}

export type ObjectProperties = Record<string, Schema>;

export interface ObjectSchema<
  Name extends string = string,
  Properties extends ObjectProperties = ObjectProperties,
> {
  kind: "object";
  name: Name;
  properties: Properties;
}

export type Schema =
  | StringSchema
  | IntegerSchema
  | NumberSchema
  | BooleanSchema
  | JsonSchema
  | EnumSchema
  | ArraySchema
  | NullableSchema
  | OptionalSchema
  | ObjectSchema;

export const schema = {
  string: { kind: "string" } as const satisfies StringSchema,
  integer: { kind: "integer" } as const satisfies IntegerSchema,
  number: { kind: "number" } as const satisfies NumberSchema,
  boolean: { kind: "boolean" } as const satisfies BooleanSchema,
  json: { kind: "json" } as const satisfies JsonSchema,
  enum: <const Name extends string, const Values extends readonly string[]>(
    name: Name,
    values: Values,
  ): EnumSchema<Name, Values> => ({ kind: "enum", name, values }),
  array: <const Item extends Schema>(item: Item): ArraySchema<Item> => ({
    kind: "array",
    item,
  }),
  nullable: <const Value extends Schema>(
    value: Value,
  ): NullableSchema<Value> => ({
    kind: "nullable",
    value,
  }),
  optional: <const Value extends Schema>(
    value: Value,
  ): OptionalSchema<Value> => ({
    kind: "optional",
    value,
  }),
  object: <
    const Name extends string,
    const Properties extends ObjectProperties,
  >(
    name: Name,
    properties: Properties,
  ): ObjectSchema<Name, Properties> => ({ kind: "object", name, properties }),
};

type OptionalPropertyNames<Properties extends ObjectProperties> = {
  [Key in keyof Properties]: Properties[Key] extends OptionalSchema
    ? Key
    : never;
}[keyof Properties];

type RequiredPropertyNames<Properties extends ObjectProperties> = Exclude<
  keyof Properties,
  OptionalPropertyNames<Properties>
>;

type InferObject<Properties extends ObjectProperties> = {
  [Key in RequiredPropertyNames<Properties>]: InferSchema<Properties[Key]>;
} & {
  [
    Key in OptionalPropertyNames<Properties>
  ]?: Properties[Key] extends OptionalSchema<infer Value>
    ? InferSchema<Value>
    : never;
};

export type InferSchema<Value extends Schema> = Value extends StringSchema
  ? string
  : Value extends IntegerSchema | NumberSchema
    ? number
    : Value extends BooleanSchema
      ? boolean
      : Value extends JsonSchema
        ? JsonValue
        : Value extends EnumSchema<string, infer Values>
          ? Values[number]
          : Value extends ArraySchema<infer Item>
            ? InferSchema<Item>[]
            : Value extends NullableSchema<infer Inner>
              ? InferSchema<Inner> | null
              : Value extends OptionalSchema<infer Inner>
                ? InferSchema<Inner> | undefined
                : Value extends ObjectSchema<string, infer Properties>
                  ? InferObject<Properties>
                  : never;

export interface MethodDefinition<
  Params extends Schema | null = Schema | null,
  Result extends Schema | null = Schema | null,
> {
  params: Params;
  result: Result;
}

export interface EventDefinition<
  Payload extends Schema | null = Schema | null,
> {
  payload: Payload;
}

export function method<
  const Params extends Schema | null,
  const Result extends Schema | null,
>(params: Params, result: Result): MethodDefinition<Params, Result> {
  return { params, result };
}

export function event<const Payload extends Schema | null>(
  payload: Payload,
): EventDefinition<Payload> {
  return { payload };
}
