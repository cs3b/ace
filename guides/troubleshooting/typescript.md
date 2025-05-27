# TypeScript Troubleshooting

Specific tools and techniques for debugging TypeScript applications, covering both server-side (Node/Deno) and client-side (browser) scenarios.

### Server‑side (Node / Deno)

* **Node inspector** – `node --inspect` (or `node --inspect --require ts-node/register app.ts`) opens Chrome DevTools or lets VS Code attach.  
* **VS Code launch config** example:  

  ```jsonc
  {
    "type": "node",
    "program": "${workspaceFolder}/src/app.ts",
    "outFiles": ["${workspaceFolder}/dist/**/*.js"]
  }
  ```  

* **Auto‑attach** in VS Code terminal for ad‑hoc scripts.  
* **Security reminder** – never expose the inspector on public interfaces in production.

### Client‑side (browser)

* **Always emit source maps** – `tsc --sourceMap` or `"sourceMap": true` in *tsconfig.json*.  
* **Chrome/Edge DevTools** display authored TypeScript when maps are present.  
* **VS Code** offers built‑in Chrome/Edge debug launchers for static HTML or `vite/webpack` dev servers.  
* **Typical flow** – set breakpoint in `.ts`, refresh page; DevTools pauses on TS line, step, inspect variables.

### Quick diagnostic checklist

1. Confirm maps load (`chrome://inspect` → “Authored” section shows *.ts*).  
2. For Node, if breakpoints never hit, check `outDir` vs `outFiles` glob mismatch.  
3. Watch out for “Cannot launch program because corresponding JavaScript cannot be found” – usually missing `sourceMap`.  
4. Deno: `deno run --inspect-brk main.ts` and attach DevTools or VS Code.
