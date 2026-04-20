/**
 * Sandbox Extension - OS-level sandboxing for bash commands
 *
 * Uses @anthropic-ai/sandbox-runtime to enforce filesystem and network
 * restrictions on bash commands at the OS level (sandbox-exec on macOS,
 * bubblewrap on Linux).
 *
 * Note: this example intentionally overrides the built-in `bash` tool to show
 * how built-in tools can be replaced. Alternatively, you could sandbox `bash`
 * via `tool_call` input mutation without replacing the tool.
 *
 * Config files (merged, project takes precedence):
 * - ~/.pi/agent/extensions/sandbox.json (global)
 * - <cwd>/.pi/sandbox.json (project-local)
 *
 * Example .pi/sandbox.json:
 * ```json
 * {
 *   "enabled": true,
 *   "network": {
 *     "allowedDomains": ["github.com", "*.github.com"],
 *     "deniedDomains": []
 *   },
 *   "filesystem": {
 *     "denyRead": ["~/.ssh", "~/.aws"],
 *     "allowWrite": [".", "/tmp"],
 *     "denyWrite": [".env"]
 *   }
 * }
 * ```
 *
 * Usage:
 * - `pi -e ./sandbox` - sandbox enabled with default/config settings
 * - `pi -e ./sandbox --no-sandbox` - disable sandboxing
 * - `/sandbox` - show current sandbox configuration
 *
 * Setup:
 * 1. Copy sandbox/ directory to ~/.pi/agent/extensions/
 * 2. Run `npm install` in ~/.pi/agent/extensions/sandbox/
 *
 * Linux also requires: bubblewrap, socat, ripgrep
 */

import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { SandboxManager, type SandboxRuntimeConfig } from "@carderne/sandbox-runtime";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { type BashOperations, createBashTool, getAgentDir, isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { homedir } from "node:os";
import { resolve } from "node:path";

interface SandboxConfig extends SandboxRuntimeConfig {
	enabled?: boolean;
	filesystem?: SandboxRuntimeConfig["filesystem"] & {
		allowRead?: string[];
	};
}

interface FileToolPolicy {
	allowRead: string[];
	denyRead: string[];
	allowWrite: string[];
	denyWrite: string[];
}

function expandHome(p: string): string {
	if (p.startsWith("~/")) return join(homedir(), p.slice(2));
	if (p === "~") return homedir();
	return p;
}

function isUnderPaths(filePath: string, paths: string[], cwd: string): boolean {
	const absolute = resolve(cwd, filePath);
	return paths.some((p) => {
		const expanded = resolve(cwd, expandHome(p));
		return absolute === expanded || absolute.startsWith(expanded + "/");
	});
}

function globToRegex(pattern: string): RegExp {
	const expanded = expandHome(pattern);
	const escaped = expanded
		.replace(/[.+^${}()|[\]\\]/g, "\\$&")
		.replace(/\*\*/g, "__GLOBSTAR__")
		.replace(/\*/g, "[^/]*")
		.replace(/__GLOBSTAR__/g, ".*")
		.replace(/\?/g, "[^/]");
	return new RegExp(`(^|/)${escaped}$`);
}

function matchesDenyPattern(filePath: string, patterns: string[], cwd: string): string | null {
	const absolute = resolve(cwd, filePath);
	for (const pattern of patterns) {
		// Directory-style pattern (no globs): prefix match
		if (!pattern.includes("*") && !pattern.includes("?")) {
			const expanded = resolve(cwd, expandHome(pattern));
			if (absolute === expanded || absolute.startsWith(expanded + "/")) return pattern;
		} else {
			if (globToRegex(pattern).test(absolute)) return pattern;
		}
	}
	return null;
}

const DEFAULT_CONFIG: SandboxConfig = {
	enabled: true,
	network: {
		allowedDomains: [
			"npmjs.org",
			"*.npmjs.org",
			"registry.npmjs.org",
			"registry.yarnpkg.com",
			"pypi.org",
			"*.pypi.org",
			"github.com",
			"*.github.com",
			"api.github.com",
			"raw.githubusercontent.com",
		],
		deniedDomains: [],
	},
	filesystem: {
		denyRead: ["~/.ssh", "~/.aws", "~/.gnupg"],
		allowWrite: [".", "/tmp"],
		denyWrite: [".env", ".env.*", "*.pem", "*.key"],
	},
};

function loadConfig(cwd: string): SandboxConfig {
	const projectConfigPath = join(cwd, ".pi", "sandbox.json");
	const globalConfigPath = join(getAgentDir(), "extensions", "sandbox.json");

	let globalConfig: Partial<SandboxConfig> = {};
	let projectConfig: Partial<SandboxConfig> = {};

	if (existsSync(globalConfigPath)) {
		try {
			globalConfig = JSON.parse(readFileSync(globalConfigPath, "utf-8"));
		} catch (e) {
			console.error(`Warning: Could not parse ${globalConfigPath}: ${e}`);
		}
	}

	if (existsSync(projectConfigPath)) {
		try {
			projectConfig = JSON.parse(readFileSync(projectConfigPath, "utf-8"));
		} catch (e) {
			console.error(`Warning: Could not parse ${projectConfigPath}: ${e}`);
		}
	}

	return deepMerge(deepMerge(DEFAULT_CONFIG, globalConfig), projectConfig);
}

function deepMerge(base: SandboxConfig, overrides: Partial<SandboxConfig>): SandboxConfig {
	const result: SandboxConfig = { ...base };

	if (overrides.enabled !== undefined) result.enabled = overrides.enabled;
	if (overrides.network) {
		result.network = { ...base.network, ...overrides.network };
	}
	if (overrides.filesystem) {
		result.filesystem = { ...base.filesystem, ...overrides.filesystem };
	}

	const extOverrides = overrides as {
		ignoreViolations?: Record<string, string[]>;
		enableWeakerNestedSandbox?: boolean;
	};
	const extResult = result as { ignoreViolations?: Record<string, string[]>; enableWeakerNestedSandbox?: boolean };

	if (extOverrides.ignoreViolations) {
		extResult.ignoreViolations = extOverrides.ignoreViolations;
	}
	if (extOverrides.enableWeakerNestedSandbox !== undefined) {
		extResult.enableWeakerNestedSandbox = extOverrides.enableWeakerNestedSandbox;
	}

	return result;
}

function createSandboxedBashOps(): BashOperations {
	return {
		async exec(command, cwd, { onData, signal, timeout }) {
			if (!existsSync(cwd)) {
				throw new Error(`Working directory does not exist: ${cwd}`);
			}

			const wrappedCommand = await SandboxManager.wrapWithSandbox(command);

			return new Promise((resolve, reject) => {
				const child = spawn("bash", ["-c", wrappedCommand], {
					cwd,
					detached: true,
					stdio: ["ignore", "pipe", "pipe"],
				});

				let timedOut = false;
				let timeoutHandle: NodeJS.Timeout | undefined;

				if (timeout !== undefined && timeout > 0) {
					timeoutHandle = setTimeout(() => {
						timedOut = true;
						if (child.pid) {
							try {
								process.kill(-child.pid, "SIGKILL");
							} catch {
								child.kill("SIGKILL");
							}
						}
					}, timeout * 1000);
				}

				child.stdout?.on("data", onData);
				child.stderr?.on("data", onData);

				child.on("error", (err) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					reject(err);
				});

				const onAbort = () => {
					if (child.pid) {
						try {
							process.kill(-child.pid, "SIGKILL");
						} catch {
							child.kill("SIGKILL");
						}
					}
				};

				signal?.addEventListener("abort", onAbort, { once: true });

				child.on("close", (code) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					signal?.removeEventListener("abort", onAbort);

					if (signal?.aborted) {
						reject(new Error("aborted"));
					} else if (timedOut) {
						reject(new Error(`timeout:${timeout}`));
					} else {
						resolve({ exitCode: code });
					}
				});
			});
		},
	};
}

export default function (pi: ExtensionAPI) {
	pi.registerFlag("no-sandbox", {
		description: "Disable OS-level sandboxing for bash commands",
		type: "boolean",
		default: false,
	});

	const localCwd = process.cwd();
	const localBash = createBashTool(localCwd);

	let sandboxEnabled = false;
	let sandboxInitialized = false;
	let policy: FileToolPolicy | null = null;

	pi.registerTool({
		...localBash,
		label: "bash (sandboxed)",
		async execute(id, params, signal, onUpdate, _ctx) {
			if (!sandboxEnabled || !sandboxInitialized) {
				return localBash.execute(id, params, signal, onUpdate);
			}

			const sandboxedBash = createBashTool(localCwd, {
				operations: createSandboxedBashOps(),
			});
			return sandboxedBash.execute(id, params, signal, onUpdate);
		},
	});

	pi.on("user_bash", () => {
		if (!sandboxEnabled || !sandboxInitialized) return;
		return { operations: createSandboxedBashOps() };
	});

	pi.on("tool_call", (event) => {
		if (!sandboxEnabled || !policy) return;

		const isRead = isToolCallEventType("read", event);
		const isWrite = isToolCallEventType("write", event);
		const isEdit = isToolCallEventType("edit", event);
		const isGrep = isToolCallEventType("grep", event);
		const isFind = isToolCallEventType("find", event);
		const isLs = isToolCallEventType("ls", event);
		if (!isRead && !isWrite && !isEdit && !isGrep && !isFind && !isLs) return;

		const path = event.input.path ?? ".";

		// Check allowRead (allowlist for all file tools)
		if (policy.allowRead.length > 0 && !isUnderPaths(path, policy.allowRead, localCwd)) {
			return { block: true, reason: `Sandbox: "${path}" is outside allowed paths (${policy.allowRead.join(", ")})` };
		}

		// Check denyRead (for reads and read-like tools)
		if (isRead || isGrep || isFind || isLs) {
			const matched = matchesDenyPattern(path, policy.denyRead, localCwd);
			if (matched) return { block: true, reason: `Sandbox: read "${path}" blocked by deny pattern "${matched}"` };
		}

		// Check denyWrite + allowWrite (for writes and edits)
		if (isWrite || isEdit) {
			const matched = matchesDenyPattern(path, policy.denyWrite, localCwd);
			if (matched) return { block: true, reason: `Sandbox: write "${path}" blocked by deny pattern "${matched}"` };

			if (policy.allowWrite.length > 0 && !isUnderPaths(path, policy.allowWrite, localCwd)) {
				return { block: true, reason: `Sandbox: write "${path}" is outside allowed write paths (${policy.allowWrite.join(", ")})` };
			}
		}
	});

	pi.on("session_start", async (_event, ctx) => {
		const noSandbox = pi.getFlag("no-sandbox") as boolean;

		if (noSandbox) {
			sandboxEnabled = false;
			ctx.ui.notify("Sandbox disabled via --no-sandbox", "warning");
			return;
		}

		const config = loadConfig(ctx.cwd);

		if (!config.enabled) {
			sandboxEnabled = false;
			ctx.ui.notify("Sandbox disabled via config", "info");
			return;
		}

		const platform = process.platform;
		if (platform !== "darwin" && platform !== "linux") {
			sandboxEnabled = false;
			ctx.ui.notify(`Sandbox not supported on ${platform}`, "warning");
			return;
		}

		try {
			const configExt = config as unknown as {
				ignoreViolations?: Record<string, string[]>;
				enableWeakerNestedSandbox?: boolean;
				allowBrowserProcess?: boolean;
			};

			await SandboxManager.initialize({
				network: config.network,
				filesystem: config.filesystem,
				ignoreViolations: configExt.ignoreViolations,
				enableWeakerNestedSandbox: configExt.enableWeakerNestedSandbox,
				allowBrowserProcess: configExt.allowBrowserProcess,
				enableWeakerNetworkIsolation: true,
			});

			// Make Node's built-in fetch() honour HTTP_PROXY / HTTPS_PROXY.
			// undici (which powers globalThis.fetch) ignores proxy env vars by default;
			// --use-env-proxy (Node 22+) opts it in.
			const nodeMajor = parseInt(process.versions.node.split(".")[0], 10);
			if (nodeMajor >= 22) {
				const existing = process.env.NODE_OPTIONS ?? "";
				process.env.NODE_OPTIONS = existing ? `${existing} --use-env-proxy` : "--use-env-proxy";
			}

			sandboxEnabled = true;
			sandboxInitialized = true;
			policy = {
				allowRead: (config as any).filesystem?.allowRead ?? [],
				denyRead: config.filesystem?.denyRead ?? [],
				allowWrite: config.filesystem?.allowWrite ?? [],
				denyWrite: config.filesystem?.denyWrite ?? [],
			};

			const networkCount = config.network?.allowedDomains?.length ?? 0;
			const writeCount = config.filesystem?.allowWrite?.length ?? 0;
			ctx.ui.setStatus(
				"sandbox",
				ctx.ui.theme.fg("accent", `🔒 Sandbox: ${networkCount} domains, ${writeCount} write paths`),
			);
			ctx.ui.notify("Sandbox initialized", "info");
		} catch (err) {
			sandboxEnabled = false;
			ctx.ui.notify(`Sandbox initialization failed: ${err instanceof Error ? err.message : err}`, "error");
		}
	});

	pi.on("session_shutdown", async () => {
		if (sandboxInitialized) {
			try {
				await SandboxManager.reset();
			} catch {
				// Ignore cleanup errors
			}
		}
	});

	pi.registerCommand("sandbox", {
		description: "Show sandbox configuration",
		handler: async (_args, ctx) => {
			if (!sandboxEnabled) {
				ctx.ui.notify("Sandbox is disabled", "info");
				return;
			}

			const config = loadConfig(ctx.cwd);
			const lines = [
				"Sandbox Configuration:",
				"",
				"Network:",
				`  Allowed: ${config.network?.allowedDomains?.join(", ") || "(none)"}`,
				`  Denied: ${config.network?.deniedDomains?.join(", ") || "(none)"}`,
				"",
				"Filesystem (bash + file tools):",
				`  Allow Read: ${(config as any).filesystem?.allowRead?.join(", ") || "(any)"}`,
				`  Deny Read: ${config.filesystem?.denyRead?.join(", ") || "(none)"}`,
				`  Allow Write: ${config.filesystem?.allowWrite?.join(", ") || "(none)"}`,
				`  Deny Write: ${config.filesystem?.denyWrite?.join(", ") || "(none)"}`,
			];
			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}
