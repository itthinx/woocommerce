/**
 * External dependencies
 */
import { test as base } from '@playwright/test';

export const test = base.extend<{ logIt: void }>({
	logIt: [
		async ({}, use) => {
			console.log( 'WPS BEFORE EACH HOOK' );
			await use();
			console.log( 'WPS AFTER EACH HOOK' );
		},
		{ auto: true },
	],
});

export { expect } from '@playwright/test';
