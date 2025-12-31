/**
 * External dependencies
 */
import { chromium, type FullConfig } from '@playwright/test';

async function globalSetup( config: FullConfig ) {
	console.log( 'WPS GLOBAL SETUP' );
}

export default globalSetup;
