//!native
//!optimize 2

const hasWarnedYet = new Set<string>();

export default function warnOnce(name: string, message: string) {
	if (!hasWarnedYet.has(name)) {
		hasWarnedYet.add(name);
		warn(message);
	}
}
