export interface Error {
	readonly message: string;
	readonly name: string;
	readonly stack?: string;
}

interface ErrorConstructor {
	new (message?: string): Error;
	(message?: string): Error;
	captureStackTrace: (error: Error, options?: Callback) => void;
}

declare const Error: ErrorConstructor;
export default Error;
