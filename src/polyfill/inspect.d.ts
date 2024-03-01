// import { HttpService } from "@rbxts/services";
// import { isArray } from "./array-utils";

// export interface InspectOptions {
// 	depth?: number;
// }

// interface FormatOptions {
// 	depth: number;
// }

// const DEFAULT_RECURSIVE_DEPTH = 2;

// export function inspect(
// 	value: unknown,
// 	// eslint-disable-next-line unicorn/no-object-as-default-parameter
// 	{ depth = DEFAULT_RECURSIVE_DEPTH }: InspectOptions = { depth: DEFAULT_RECURSIVE_DEPTH },
// ): string {
// 	isArray;
// 	const formatOptions: FormatOptions = { depth: depth >= 0 ? depth : DEFAULT_RECURSIVE_DEPTH };
// 	return "";
// }

// export default inspect;

export interface InspectOptions {
	depth?: number;
}

export function inspect(value: unknown, options?: InspectOptions): string;
export default inspect;
