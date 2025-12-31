// const config = require( '../../playwright.config.js' );
//
// process.env.USE_WP_ENV = 'true';
//
// module.exports = config;

// import { test, expect } from './automatic';

// import { test } from '@playwright/test';
// test.beforeEach(async({browser})=>{console.log('BANANA')});

let config = require( '../../playwright.config.js' );

process.env.USE_WP_ENV = 'true';

console.log( 'WPS PLAYWRIGHT' ); // @todo remove

// https://playwright.dev/docs/next/test-projects#running-sequence

config = {
	...config.default,
	projects: [
		...config.setupProjects,
//		{
//			name: 'reset',
//			testDir: `${ config.TESTS_ROOT_PATH }/fixtures`,
//			testMatch: 'reset.setup.js',
//		},
//		{
//			name: 'wps global setup',
//			testDir: `${ config.TESTS_ROOT_PATH }/envs/default-wps`,
//			testMatch: './global-setup.ts',
//			dependencies: [ 'site setup' ],
//		},
		{
			name: 'wps',
			testDir: `${ config.TESTS_ROOT_PATH }/envs/default-wps`,
			testMatch: 'wps.setup.js',
			dependencies: [ 'site setup' ],
		},
		{
			name: 'e2e-wps',
			testIgnore: '**/api-tests/**',
			dependencies: [ 'wps' ],
		},
	],
	timeout: 333 * 1000, // sync with indexer wait processing and a bit more
	// This only runs once before any tests ...
	// globalSetup: require.resolve( './global-setup' ),
	// ... so this is no good for our purpose of checking if the indexer is up-to-date with products
};

// config.reporter.push( [ `${ config.TESTS_ROOT_PATH }/envs/default-wps/reporter.ts` ] );
config.reporter.push( [ './reporter.ts' ] );

//console.log( 'config = ', config ); // @todo remove

module.exports = config;
