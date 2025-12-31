/**
 * External dependencies
 */
import { Fixture, test as base } from '@playwright/test';

console.log( 'WPS GLOBAL SETUP' ); // @todo remove

const beforeEach = async ({ page }: Fixture) => {
	console.log( 'WPS BEFOREEACH' );
};

export default beforeEach;
