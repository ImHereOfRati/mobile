import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
  BRIDGE_VERSION,
  bridgeContract,
  MINIMUM_BRIDGE_VERSION,
} from "../src/contract";
import type {
  EnumSchema,
  ObjectSchema,
  OptionalSchema,
  Schema,
} from "../src/schema";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "../../../..");
const outputPath = path.join(
  repositoryRoot,
  "lib",
  "shell",
  "bridge",
  "generated",
  "bridge_contract.generated.dart",
);

type NamedSchema = EnumSchema | ObjectSchema;

function collectNamedSchemas() {
  const schemas = new Map<string, NamedSchema>();

  function visit(value: Schema | null) {
    if (value === null) return;

    switch (value.kind) {
      case "enum":
        schemas.set(value.name, value);
        return;
      case "object":
        if (!schemas.has(value.name)) {
          schemas.set(value.name, value);
          Object.values(value.properties).forEach(visit);
        }
        return;
      case "array":
        visit(value.item);
        return;
      case "nullable":
      case "optional":
        visit(value.value);
        return;
      case "boolean":
      case "integer":
      case "json":
      case "number":
      case "string":
        return;
    }
  }

  Object.values(bridgeContract.methods).forEach(({ params, result }) => {
    visit(params);
    visit(result);
  });
  Object.values(bridgeContract.events).forEach(({ payload }) => visit(payload));

  return [...schemas.values()];
}

function dartType(value: Schema): string {
  switch (value.kind) {
    case "string":
      return "String";
    case "integer":
      return "int";
    case "number":
      return "double";
    case "boolean":
      return "bool";
    case "json":
      return "Object?";
    case "enum":
    case "object":
      return value.name;
    case "array":
      return `List<${dartType(value.item)}>`;
    case "nullable":
    case "optional": {
      const innerType = dartType(value.value);
      return innerType.endsWith("?") ? innerType : `${innerType}?`;
    }
  }
}

function decode(value: Schema, expression: string): string {
  switch (value.kind) {
    case "string":
      return `${expression} as String`;
    case "integer":
      return `(${expression} as num).toInt()`;
    case "number":
      return `(${expression} as num).toDouble()`;
    case "boolean":
      return `${expression} as bool`;
    case "json":
      return expression;
    case "enum":
      return `${value.name}.values.byName(${expression} as String)`;
    case "object":
      return `${value.name}.fromJson(${expression} as Map<String, Object?>)`;
    case "array":
      return `(${expression} as List<Object?>).map((item) => ${decode(value.item, "item")}).toList()`;
    case "nullable":
    case "optional":
      return `${expression} == null ? null : ${decode(value.value, expression)}`;
  }
}

function encode(value: Schema, expression: string): string {
  switch (value.kind) {
    case "string":
    case "integer":
    case "number":
    case "boolean":
    case "json":
      return expression;
    case "enum":
      return `${expression}.name`;
    case "object":
      return `${expression}.toJson()`;
    case "array":
      return `${expression}.map((item) => ${encode(value.item, "item")}).toList()`;
    case "nullable":
    case "optional":
      return `${expression} == null ? null : ${encode(value.value, `${expression}!`)}`;
  }
}

function generateEnum(value: EnumSchema) {
  return `enum ${value.name} {\n${value.values
    .map((entry) => `  ${entry},`)
    .join("\n")}\n}`;
}

function isOptional(value: Schema): value is OptionalSchema {
  return value.kind === "optional";
}

function generateObject(value: ObjectSchema) {
  const entries = Object.entries(value.properties);
  const constructor = entries
    .map(([name, property]) =>
      isOptional(property) ? `    this.${name},` : `    required this.${name},`,
    )
    .join("\n");
  const fields = entries
    .map(([name, property]) => `  final ${dartType(property)} ${name};`)
    .join("\n");
  const fromJson = entries
    .map(
      ([name, property]) =>
        `      ${name}: ${decode(property, `json['${name}']`)},`,
    )
    .join("\n");
  const toJson = entries
    .map(([name, property]) => {
      if (isOptional(property)) {
        return `      if (${name} != null) '${name}': ${encode(property.value, `${name}!`)},`;
      }
      return `      '${name}': ${encode(property, name)},`;
    })
    .join("\n");

  return `class ${value.name} {
  const ${value.name}({
${constructor}
  });

${fields}

  factory ${value.name}.fromJson(Map<String, Object?> json) {
    return ${value.name}(
${fromJson}
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
${toJson}
    };
  }
}`;
}

function generateDart() {
  const declarations = collectNamedSchemas()
    .map((value) =>
      value.kind === "enum" ? generateEnum(value) : generateObject(value),
    )
    .join("\n\n");
  const methodNames = Object.keys(bridgeContract.methods)
    .map((name) => `  '${name}',`)
    .join("\n");
  const eventNames = Object.keys(bridgeContract.events)
    .map((name) => `  '${name}',`)
    .join("\n");

  return `// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: web/packages/bridge-contract/src/contract.ts
// Run: pnpm bridge:generate
// ignore_for_file: prefer_if_null_operators, prefer_null_aware_operators

const bridgeContractVersion = '${BRIDGE_VERSION}';
const minimumBridgeContractVersion = '${MINIMUM_BRIDGE_VERSION}';

const bridgeMethodNames = <String>[
${methodNames}
];

const bridgeEventNames = <String>[
${eventNames}
];

${declarations}
`;
}

const expected = generateDart().replaceAll("\r\n", "\n");
const checkOnly = process.argv.includes("--check");

if (checkOnly) {
  const current = await readFile(outputPath, "utf8").catch(() => "");
  if (current.replaceAll("\r\n", "\n") !== expected) {
    throw new Error(
      "Generated Dart bridge contract is stale. Run `pnpm bridge:generate`.",
    );
  }
  console.log("Generated Dart bridge contract is up to date.");
} else {
  await mkdir(path.dirname(outputPath), { recursive: true });
  await writeFile(outputPath, expected, "utf8");
  console.log(path.relative(repositoryRoot, outputPath));
}
