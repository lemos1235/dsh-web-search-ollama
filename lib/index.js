export const name = "web-search-ollama";
export const inject = ["web"];

const PROVIDER_ID = "ollama";
const DEFAULT_HOST = "http://127.0.0.1:11434";

class WebError extends Error {
	constructor(message, code, options) {
		super(message, options);
		this.name = "WebError";
		this.code = code;
	}
}

function normalizeHost(host) {
	return String(host ?? DEFAULT_HOST).replace(/\/+$/u, "");
}

function isAbortError(error) {
	return error instanceof DOMException && error.name === "AbortError";
}

function aborted(kind, signal, fallback) {
	return new WebError(
		`Ollama ${kind} aborted`,
		"WEB_ABORTED",
		{ cause: signal?.aborted === true ? signal.reason : fallback },
	);
}

async function postJson(url, body, signal, kind) {
	let response;
	try {
		response = await fetch(url, {
			method: "POST",
			redirect: "error",
			headers: {
				"content-type": "application/json",
				accept: "application/json",
			},
			body: JSON.stringify(body),
			...(signal !== undefined ? { signal } : {}),
		});
	} catch (error) {
		if (signal?.aborted === true || isAbortError(error)) throw aborted(kind, signal, error);
		throw new WebError(`Ollama ${kind} request failed: ${String(error)}`, "WEB_PROVIDER_ERROR", { cause: error });
	}

	const text = await response.text();
	let parsed;
	try {
		parsed = text.length === 0 ? {} : JSON.parse(text);
	} catch (error) {
		throw new WebError(
			`Ollama ${kind} returned non-JSON (HTTP ${response.status}): ${text.slice(0, 240)}`,
			"WEB_PROVIDER_ERROR",
			{ cause: error },
		);
	}

	if (!response.ok) {
		const detail = parsed.error ?? parsed.message ?? text.slice(0, 240);
		throw new WebError(`Ollama ${kind} error (HTTP ${response.status}): ${detail}`, "WEB_PROVIDER_ERROR");
	}
	return parsed;
}

async function postFirstOk(host, paths, body, signal, kind) {
	let last404;
	for (const path of paths) {
		try {
			return await postJson(`${host}${path}`, body, signal, kind);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			if (message.includes("HTTP 404")) {
				last404 = error;
				continue;
			}
			throw error;
		}
	}
	throw last404 ?? new WebError(`Ollama ${kind} endpoint not found on ${host}`, "WEB_PROVIDER_ERROR");
}

class OllamaSearchProvider {
	constructor(host) {
		this.id = PROVIDER_ID;
		this.host = host;
	}

	available() {
		return URL.canParse(this.host);
	}

	async search(request, signal) {
		const maxResults = Math.min(Math.max(request.maxResults ?? 5, 1), 10);
		const payload = await postFirstOk(
			this.host,
			["/api/experimental/web_search", "/api/web_search"],
			{ query: request.query, max_results: maxResults },
			signal,
			"search",
		);
		const results = Array.isArray(payload.results) ? payload.results : [];
		const sources = [];
		const seen = new Set();
		for (const item of results) {
			const url = typeof item?.url === "string" ? item.url : "";
			if (url.length === 0 || seen.has(url)) continue;
			seen.add(url);
			sources.push({
				url,
				...(typeof item.title === "string" && item.title.length > 0 ? { title: item.title } : {}),
				...(typeof item.content === "string" && item.content.length > 0 ? { snippet: item.content } : {}),
			});
		}
		return { sources, truncated: false };
	}
}

class OllamaFetchProvider {
	constructor(host) {
		this.id = PROVIDER_ID;
		this.host = host;
	}

	available() {
		return URL.canParse(this.host);
	}

	async fetch(request, signal) {
		const payload = await postFirstOk(
			this.host,
			["/api/experimental/web_fetch", "/api/web_fetch"],
			{ url: request.url },
			signal,
			"fetch",
		);
		const content = typeof payload.content === "string" ? payload.content : "";
		return {
			url: request.url,
			statusCode: 200,
			body: { kind: "text", content },
			truncated: false,
		};
	}
}

export function apply(ctx, config = {}) {
	const host = normalizeHost(config.host);
	ctx.web.registerSearchProvider(new OllamaSearchProvider(host));
	ctx.web.registerFetchProvider(new OllamaFetchProvider(host));
}
