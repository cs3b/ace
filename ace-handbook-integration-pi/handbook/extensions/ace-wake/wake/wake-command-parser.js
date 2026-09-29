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
 * Parsing is token-based: quoted values (including values that contain text
 * resembling options, e.g. --path "logs/--message.txt") stay single tokens,
 * quoted spans embedded in --flag=value tokens (e.g. --message="check the
 * build") keep their full value, and option names match exactly, so
 * "--message-prefix" never satisfies "--message". Unquoted message text may
 * span the remaining tokens; unterminated quotes are rejected.
 *
 * @param {string} kind "loop" or "watch", used for error text only.
 * @param {string} input Raw argument string after the command name.
 * @returns {{subcommand: string, name?: string, flags: Record<string, string>, message?: string}}
 */
export function parseWakeCommand(kind, input) {
  const tokens = tokenize((input ?? "").trim());
  const subcommand = tokens[0]?.text;
  if (!subcommand) {
    throw new WakeError(usage(kind));
  }

  if (subcommand === "list") {
    if (tokens.length > 1) {
      throw new WakeError(`${kind} list takes no arguments`);
    }
    return { subcommand };
  }

  if (subcommand === "remove") {
    if (tokens.length !== 2) {
      throw new WakeError(`usage: /${kind} remove NAME`);
    }
    return { subcommand, name: tokens[1].text };
  }

  if (subcommand !== "add") {
    throw new WakeError(`unknown ${kind} subcommand: ${subcommand}; ${usage(kind)}`);
  }

  if (tokens.length < 2) {
    throw new WakeError(usage(kind));
  }

  const name = tokens[1].text;
  const { flags, message } = parseFlags(kind, tokens.slice(2));

  return { subcommand, name, flags, message };
}

function usage(kind) {
  if (kind === "loop") {
    return "usage: /loop add NAME --interval SECONDS --message TEXT | /loop list | /loop remove NAME";
  }
  return "usage: /watch add NAME --path PATH --message TEXT | /watch list | /watch remove NAME";
}

/**
 * Split an argument string into tokens. A quote opens a quoted span only at
 * the start of a token or immediately after `=` — so `--message="check the
 * build"` and `--path="my file.txt"` keep their full values, while prose
 * apostrophes mid-token (`don't`) stay literal. Inside a span, backslash
 * escapes are honored and the span may contain whitespace and text
 * resembling options; quotes are stripped. Unterminated spans are rejected
 * instead of silently accepting the partial fragment.
 *
 * @param {string} raw
 * @returns {Array<{text: string, quoted: boolean}>}
 */
function tokenize(raw) {
  const tokens = [];
  let index = 0;
  while (index < raw.length) {
    if (/\s/.test(raw[index])) {
      index += 1;
      continue;
    }
    const tokenStart = index;
    const leadingQuote = raw[tokenStart];
    let text = "";
    while (index < raw.length && !/\s/.test(raw[index])) {
      const character = raw[index];
      const opensSpan = (character === "\"" || character === "'")
        && (index === tokenStart || raw[index - 1] === "=");
      if (!opensSpan) {
        text += character;
        index += 1;
        continue;
      }
      index += 1;
      let value = "";
      while (index < raw.length && raw[index] !== character) {
        if (raw[index] === "\\" && index + 1 < raw.length) {
          value += raw[index + 1];
          index += 2;
          continue;
        }
        value += raw[index];
        index += 1;
      }
      if (index >= raw.length) {
        throw new WakeError(`unterminated quoted value starting at position ${tokenStart}`);
      }
      index += 1;
      text += value;
    }
    tokens.push({ text, quoted: leadingQuote === "\"" || leadingQuote === "'" });
  }
  return tokens;
}

/**
 * Extract --flag value pairs and the trailing message from add-tokens.
 * Option names match exactly; an unquoted --message value spans all
 * remaining tokens (joined with single spaces) since it is documented last.
 *
 * @param {string} kind
 * @param {Array<{text: string, quoted: boolean}>} tokens
 */
function parseFlags(kind, tokens) {
  const valueFlags = kind === "loop" ? ["interval", "message"] : ["path", "message"];
  const flags = {};
  let message;
  let index = 0;
  while (index < tokens.length) {
    const token = tokens[index];
    if (!token.text.startsWith("--") || token.quoted) {
      index += 1;
      continue;
    }
    const [flagName, inlineValue] = token.text.slice(2).split(/=(.*)/s, 2);
    if (!valueFlags.includes(flagName)) {
      index += 1;
      continue;
    }
    if (inlineValue !== undefined) {
      if (flagName === "message") {
        message = inlineValue;
      } else {
        flags[flagName] = inlineValue;
      }
      index += 1;
      continue;
    }
    if (flagName === "message") {
      const rest = tokens.slice(index + 1);
      if (rest.length === 0) {
        throw new WakeError("message must not be empty");
      }
      message = rest.map((token_) => token_.text).join(" ");
      index = tokens.length;
      continue;
    }
    const value = tokens[index + 1];
    if (value === undefined) {
      throw new WakeError(`${flagName} requires a value`);
    }
    flags[flagName] = value.text;
    index += 2;
  }
  return { flags, message };
}
