//!native
//!optimize 2

import type { Root } from "@rbxts/react-roblox";
import { t } from "@rbxts/t";

export const isMaybeInstance = t.optional(t.Instance);
export const isKey = t.union(t.number, t.string);

export interface ReactHandle {
	readonly key: number | string;
	readonly parent: Instance;
	readonly root: Root;
}
export const isReactHandle: t.check<ReactHandle> = t.strictInterface({
	key: isKey,
	parent: t.Instance,
	root: t.interface({
		render: t.callback,
		unmount: t.callback,
	}),
});
