import { WakeError } from "./types.js";

/**
 * Parse the argument string of a /loop or /watch command.
 *
 * Supported forms:
 *   add NAME --interval SECONDS --message TEXT
 *   add NAME --path PATH --message TEXT
 *   list
 *   remove NAME
 *
 * The message is the trailing argument and may contain spaces or quoted
 * text. Flag values accept both "--flag value" and "--flag=value".
 *
 * @param {string} kind "loop" or "watch", used for error text only.
 * @param {string} input Raw argument string after the command name.
 * @returns {{subcommand: string, name?: string, flags: Record<string, string>}}
 */
export function parseWakeCommand(kind, input) {
  const raw = (input ?? "").trim();
  const [subcommand, ...rest] = raw.split(/\s+/).filter(Boolean);
  if (!subcommand) {
    throw new WakeError(usage(kind));
  }

  if (subcommand === "list") {
    if (rest.length > 0) {
      throw new WakeError(`${kind} list takes no arguments`);
    }
    return { subcommand };
  }

  if (subcommand === "remove") {
    if (rest.length !== 1) {
      throw new WakeError(`usage: /${kind} remove NAME`);
    }
    return { subcommand, name: rest[0] };
  }

  if (subcommand !== "add") {
    throw new WakeError(`unknown ${kind} subcommand: ${subcommand}; ${usage(kind)}`);
  }

  if (rest.length === 0) {
    throw new WakeError(usage(kind));
  }

  const name = rest[0];
  const subIndex = raw.indexOf(subcommand);
  const nameIndex = raw.indexOf(name, subIndex + subcommand.length);
  const tail = raw.slice(nameIndex + name.length);
  const message = takeTrailingValue(tail, "message");
  const withoutMessage = message === undefined ? tail : tail.slice(0, tail.lastIndexOf(`--message`));
  const flags = {};
  for (const flag of kind === "loop" ? ["interval"] : ["path"]) {
    const value = takeFlagValue(withoutMessage, flag);
    if (value !== undefined) {
      flags[flag] = value;
    }
  }

  return { subcommand, name, flags, message };
}

function usage(kind) {
  if (kind === "loop") {
    return 'usage: /loop add NAME --interval SECONDS --message TEXT | /loop list | /loop remove NAME';
  }
  return 'usage: /watch add NAME --path PATH --message TEXT | /watch list | /watch remove NAME';
}

function takeTrailingValue(raw, flag) {
  const token = `--${flag}`;
  const index = raw.indexOf(token);
  if (index === -1) {
    return undefined;
  }
  let value = raw.slice(index + token.length).trim();
  if (value.startsWith("=")) {
    value = value.slice(1).trim();
  }
  return stripQuotes(value);
}

function takeFlagValue(raw, flag) {
  // Quoted values match before the bare token so paths with spaces survive;
  // the quote characters are stripped afterwards.
  const match = raw.match(new RegExp(`--${flag}(?:=|\\s+)("(?:[^"\\\\]|\\\\.)*"|'(?:[^'\\\\]|\\\\.)*'|\\S+)`));
  return match ? stripQuotes(match[1]) : undefined;
}

function stripQuotes(value) {
  if (value.length >= 2 && ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))) {
    return value.slice(1, -1);
  }
  return value;
}
