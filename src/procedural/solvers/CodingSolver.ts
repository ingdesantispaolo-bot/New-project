type CodingValue = number | boolean | string;

/**
 * A tiny interpreter for the limited pseudo-code emitted by CodingPuzzleGenerator.
 * It executes "predict the output" programs (assignments, Italian/English loops,
 * if/else and inline if/elif/else, boolean AND/OR/NOT) and returns the printed
 * value as a string. Returns `undefined` for anything it does not understand, so
 * the validator can treat "not computable" distinctly from "wrong answer".
 *
 * Grammar is closed (only what the generator produces); the test suite fuzzes
 * hundreds of generated puzzles and asserts the solver agrees with the declared
 * answer, which guards both the generator and this interpreter.
 */
export class CodingSolver {
  run(codeLines: string[]): string | undefined {
    try {
      const vars = new Map<string, CodingValue>();
      const lines = codeLines
        .map((raw) => ({ indent: raw.length - raw.trimStart().length, text: raw.trim() }))
        .filter((line) => line.text.length > 0 && !line.text.startsWith("#"));

      let output: string | undefined;
      const execStatement = (text: string): void => {
        if (text.startsWith("stampa ")) {
          output = this.stringify(this.value(text.slice(7).trim(), vars));
          return;
        }
        const eq = text.indexOf("=");
        if (eq <= 0) {
          throw new Error(`unparsed: ${text}`);
        }
        const name = text.slice(0, eq).trim();
        vars.set(name, this.evalExpression(text.slice(eq + 1).trim(), vars));
      };

      const collectBlock = (start: number, baseIndent: number): typeof lines => {
        const body: typeof lines = [];
        let k = start;
        while (k < lines.length && lines[k].indent > baseIndent) {
          body.push(lines[k]);
          k += 1;
        }
        return body;
      };

      let i = 0;
      while (i < lines.length) {
        const line = lines[i];
        const text = line.text;

        const ripeti = text.match(/^ripeti\s+(\d+)\s+volte\s*:$/);
        const indexedLoop = text.match(/^(?:for\s+(\w+)\s+in\s+1\.\.|per\s+(\w+)\s+da\s+1\s+a\s+)(\d+)\s*:$/);
        const seHeader = text.match(/^se\s+(.+):$/);
        const italianInline = /^(?:se\s+.+|oppure se\s+.+|altrimenti\s*):\s*\S/.test(text);
        const englishInline = /^(if|elif|else)\b/.test(text);

        if (ripeti || indexedLoop) {
          const count = Number(ripeti ? ripeti[1] : indexedLoop![3]);
          const indexVar = indexedLoop ? (indexedLoop[1] ?? indexedLoop[2]) : undefined;
          const body = collectBlock(i + 1, line.indent);
          for (let n = 1; n <= count; n += 1) {
            if (indexVar) vars.set(indexVar, n);
            body.forEach((stmt) => execStatement(stmt.text));
          }
          i += 1 + body.length;
        } else if (seHeader) {
          const condition = seHeader[1].trim();
          const thenBody = collectBlock(i + 1, line.indent);
          let j = i + 1 + thenBody.length;
          let elseBody: typeof lines = [];
          if (lines[j] && /^altrimenti\s*:$/.test(lines[j].text)) {
            elseBody = collectBlock(j + 1, lines[j].indent);
            j += 1 + elseBody.length;
          }
          (this.evalCondition(condition, vars) ? thenBody : elseBody).forEach((stmt) => execStatement(stmt.text));
          i = j;
        } else if (italianInline || englishInline) {
          // A chain of inline conditionals, one per line: the first true branch
          // runs its statement, the rest are skipped. Handles both dialects:
          //   if / elif / else            and   se / oppure se / altrimenti
          const isChainLine = (t: string): boolean =>
            /^(if|elif|else)\b/.test(t) || /^(?:se\s+.+|oppure se\s+.+|altrimenti\s*):\s*\S/.test(t);
          let resolved = false;
          while (i < lines.length && isChainLine(lines[i].text)) {
            const current = lines[i].text;
            const branch = current.match(/^(?:if|elif|oppure se|se)\s+(.+?):\s*(.+)$/);
            const elseBranch = current.match(/^(?:else|altrimenti)\s*:\s*(.+)$/);
            if (branch) {
              if (!resolved && this.evalCondition(branch[1].trim(), vars)) {
                execStatement(branch[2].trim());
                resolved = true;
              }
            } else if (elseBranch) {
              if (!resolved) {
                execStatement(elseBranch[1].trim());
                resolved = true;
              }
            }
            i += 1;
          }
        } else {
          execStatement(text);
          i += 1;
        }
      }
      return output;
    } catch {
      return undefined;
    }
  }

  private evalExpression(expression: string, vars: Map<string, CodingValue>): CodingValue {
    const expr = expression.trim();
    if (/\bOR\b/.test(expr)) {
      return expr.split(/\bOR\b/).some((part) => this.asBool(this.evalExpression(part, vars)));
    }
    if (/\bAND\b/.test(expr)) {
      return expr.split(/\bAND\b/).every((part) => this.asBool(this.evalExpression(part, vars)));
    }
    if (/^NOT\b/.test(expr)) {
      return !this.asBool(this.evalExpression(expr.replace(/^NOT\b/, ""), vars));
    }
    const binary = expr.match(/^(\S+)\s*([+\-*/])\s*(\S+)$/);
    if (binary) {
      const left = this.numericValue(binary[1], vars);
      const right = this.numericValue(binary[3], vars);
      switch (binary[2]) {
        case "+": return left + right;
        case "-": return left - right;
        case "*": return left * right;
        case "/": return right === 0 ? NaN : left / right;
      }
    }
    return this.value(expr, vars);
  }

  private evalCondition(condition: string, vars: Map<string, CodingValue>): boolean {
    const match = condition.match(/^(.+?)\s*(>=|<=|==|!=|<|>)\s*(.+)$/);
    if (!match) {
      return this.asBool(this.value(condition.trim(), vars));
    }
    const left = this.numericValue(match[1], vars);
    const right = this.numericValue(match[3], vars);
    switch (match[2]) {
      case ">=": return left >= right;
      case "<=": return left <= right;
      case "==": return left === right;
      case "!=": return left !== right;
      case "<": return left < right;
      case ">": return left > right;
    }
    return false;
  }

  /** Resolve a token (literal number/string/boolean or variable) to its value. */
  private value(token: string, vars: Map<string, CodingValue>): CodingValue {
    const trimmed = token.trim();
    if (/^-?\d+$/.test(trimmed)) return Number(trimmed);
    if (/^".*"$/.test(trimmed)) return trimmed.slice(1, -1);
    if (trimmed === "vero" || trimmed === "true") return true;
    if (trimmed === "falso" || trimmed === "false") return false;
    if (vars.has(trimmed)) return vars.get(trimmed)!;
    return trimmed; // bareword string (e.g. LOW / MID / HIGH)
  }

  private numericValue(token: string, vars: Map<string, CodingValue>): number {
    const value = this.value(token, vars);
    return typeof value === "number" ? value : Number(value);
  }

  private asBool(value: CodingValue): boolean {
    return value === true || value === "vero" || value === "true";
  }

  private stringify(value: CodingValue): string {
    if (typeof value === "boolean") return value ? "vero" : "falso";
    return String(value);
  }
}
