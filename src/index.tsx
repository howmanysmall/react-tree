//!native
//!nonstrict
//!optimize 2
/* eslint-disable prefer-const */

import React from "@rbxts/react";
import { act, createLegacyRoot, createPortal, createRoot } from "@rbxts/react-roblox";
import isDevelopment from "./is-development";
import Error from "./polyfill/error";
import inspect from "./polyfill/inspect";
import { isKey, isMaybeInstance, isReactHandle, type ReactHandle as ReactHandle_ } from "./type-checks";
import warnOnce from "./warn-once";

/**
 * A utility library that allows Roact styled mounting and unmounting for React.
 */
namespace ReactTree {
	/**
	 * Whether or not to perform strict validation on the React tree.
	 */
	// biome-ignore lint/style/useConst: shut up
	export let strictValidation = false;
	// biome-ignore lint/style/useConst: shut up
	export let react17CompatibleLegacyRoot = false;
	// biome-ignore lint/style/useConst: shut up
	export let react17InlineAct = false;

	/**
	 * Whether or not to use _G.__DEV__ mode. Defaults to
	 * `_G.__DEV__`.
	 */
	// biome-ignore lint/style/useConst: shut up
	export let development = isDevelopment();

	export type ReactHandle = ReactHandle_;

	/**
	 * Used to mount a React element into the Roblox instance tree.
	 *
	 * Creates a Roblox Instance given a Roact element, and optionally a
	 * `parent` to put it in, and a `key` to use as the instance's `Name`.
	 *
	 * The return result is an {@linkcode ReactHandle}, which can be used to unmount
	 * the element later using {@linkcode unmount}.
	 *
	 * @param element The React element to mount. This is the return result of `React.createElement`.
	 * @param parent Where you want to mount the tree to.
	 * @param key The key of the element. Essentially just `Instance.Name`.
	 * @returns The handle to the mounted element.
	 */
	export function mount(element: React.ReactElement, parent?: Instance, key?: string): ReactHandle {
		if (strictValidation) {
			if (!isMaybeInstance(parent)) {
				const exception = new Error(`Expected Instance? for parent, got ${inspect(parent)}`);
				Error.captureStackTrace(exception, mount);
				throw exception;
			}

			if (!isKey(key)) {
				const exception = new Error(`Expected number | string | undefined for key, got ${inspect(key)}`);
				Error.captureStackTrace(exception, mount);
				throw exception;
			}
		}

		if (parent && !typeIs(parent, "Instance")) {
			const exception = new Error(
				"Cannot mount element (`%*`) into a parent that is not a Roblox Instance (got type `%*`) \n%*".format(
					element ? `${element.type}` : "<unknown>",
					typeOf(parent),
					parent === undefined ? "" : inspect(parent),
				),
			);
			Error.captureStackTrace(exception, mount);
			throw exception;
		}

		const root = react17CompatibleLegacyRoot
			? createLegacyRoot(new Instance("Folder"))
			: createRoot(new Instance("Folder"));

		let trueParent: Instance;
		if (parent === undefined) {
			trueParent = new Instance("Folder");
			trueParent.Name = "Target";
		} else trueParent = parent;

		if (key === undefined) key = react17CompatibleLegacyRoot ? "ReactLegacyRoot" : "ReactRoot";

		if (react17InlineAct) act(() => root.render(createPortal(<folder key={key}>{element}</folder>, trueParent)));
		else root.render(createPortal(<folder key={key}>{element}</folder>, trueParent));

		return {
			key: `${key}`,
			parent: trueParent,
			root,
		};
	}

	/**
	 * Unmounts an element that was mounted with {@linkcode mount}.
	 * @param reactHandle The handle to unmount.
	 */
	export function unmount(reactHandle: ReactHandle) {
		if (strictValidation && !isReactHandle(reactHandle)) {
			const exception = new Error(`Expected ReactHandle, got ${inspect(reactHandle)}`);
			Error.captureStackTrace(exception, unmount);
			throw exception;
		}

		if (react17InlineAct)
			act(() => {
				reactHandle.root.unmount();
				table.clear(reactHandle);
			});
		else {
			reactHandle.root.unmount();
			table.clear(reactHandle);
		}
	}

	/**
	 * Updates an existing instance handle with a new element, returning
	 * the same handle. This can be used to update a UI created with
	 * {@linkcode mount} by passing in a new element with new props.
	 *
	 * @deprecated This is really not recommended to use, it's extremely slow and can cause major performance issues. Find a better way to handle your trees.
	 *
	 * @param reactHandle The handle to update.
	 * @param element The new element to update the handle with. This is the return result of `React.createElement`.
	 * @returns The same handle that was passed in.
	 */
	export function update(reactHandle: ReactHandle, element: React.ReactElement) {
		if (strictValidation && !isReactHandle(reactHandle)) {
			const exception = new Error(`Expected ReactHandle, got ${inspect(reactHandle)}`);
			Error.captureStackTrace(exception, update);
			throw exception;
		}

		if (development)
			warnOnce(
				"ReactTree.update",
				"You shouldn't really be using ReactTree.update, find a better way to handle your trees.",
			);

		const { key, parent } = reactHandle;

		if (react17InlineAct)
			act(() => reactHandle.root.render(createPortal(<folder key={key}>{element}</folder>, parent)));
		else reactHandle.root.render(createPortal(<folder key={key}>{element}</folder>, parent));

		return reactHandle;
	}
}

export = ReactTree;
