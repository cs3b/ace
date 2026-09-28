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
 * and option names match exactly, so "--message-prefix" never satisfies
 * "--message". Unquoted message text may span the remaining tokens.
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
 * Split an argument string into tokens: quoted spans become single tokens
 * (quotes stripped, backslash escapes honored); everything else splits on
 * whitespace.
 *
 * @param {string} raw
 * @returns {Array<{text: string, quoted: boolean}>}
 */
function tokenize(raw) {
  const tokens = [];
  const pattern = /"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)'|(\S+)/g;
  let match;
  while ((match = pattern.exec(raw)) !== null) {
    if (match[1] !== undefined) {
      tokens.push({ text: unfoldEscapes(match[1]), quoted: true });
    } else if (match[2] !== undefined) {
      tokens.push({ text: unfoldEscapes(match[2]), quoted: true });
    } else {
      tokens.push({ text: match[3], quoted: false });
    }
  }
  return tokens;
}

function unfoldEscapes(value) {
  return value.replace(/\\(.)/g, "$1");
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
