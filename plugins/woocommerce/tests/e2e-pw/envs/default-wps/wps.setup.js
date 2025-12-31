/**
 * External dependencies
 */
import { test as base } from '@playwright/test';

/**
 * Internal dependencies
 */
import { test as setup } from '../../fixtures/fixtures';

// only good for own project
setup.beforeEach( () => {
	console.log( 'WPS BEFORE' );
} );


// https://github.com/microsoft/playwright/issues/12396
exports.test = base.test.extend( {
	_autoAttachMetadata: [async ({ browser, browserName }, use, testInfo) => {
		
		
		console.log( 'WPS **********' ); // @todo remove
	        // BEFORE: Generate an attachment for the test with the required info
	        await testInfo.attach('metadata.json', {
	            body: JSON.stringify({
	                version: browser.version(),
	                name: browserName,
	                arch: os.arch(),
	                platform: os.platform(),
	            })
	        })

	        // ---------------------------------------------------------
	        await use(/** our test doesn't need this fixture direcly */);
	        // ---------------------------------------------------------

	        // AFTER: There's nothing to cleanup in this fixutre
	    }, { auto: true }],
} );

function waitASecond() {
	return new Promise( resolve => setTimeout( resolve, 1000 ) );
}

setup( 'wait for indexer', async ( { restApi } ) => {
	try {

		// THE GENERAL IDEA THAT COULD WORK:
		// we run a bit of code here BEFORE ANY TEST
		// which waits until the number of products
		// indexed equals the number of products

		// @todo we can compare the number of products returned by the WC REST API call
		// with the number of products that WPS REST API returns
		// or can we get it from e2e-pw/tests/product/product-import-csv.spec.js
		// which defines the productNames const and just count those?
		// But if something changes, this won't work anymore, so it seems
		// the best way is to do the WC REST API call.
//		const products = await restApi.get(
//			`wc/v3/products`,
//			{
//				params: {
//					_fields: [ 'id' ],
//					limit: '-1' // @todo right?
//				},
//			},
//		);
//		if ( products.status >= 200 && products.status < 400 ) {
//			if (
//				typeof products.request !== 'undefined' &&
//				typeof products.request.data !== 'undefined'
//			) {
//				// @todo count products
//			}
//		}
//		console.log( 'products : ', products ); // @todo remove

		const maxFails = 10;
		const maxSame = 30;
		let fails = 0;
		let response = null;
		let lastTotal = null;
		let same = 0;
		// wait up to 5 minutes OR
		// until the number of products stays invariant for 30 seconds OR
		// 10 attempts to obtain the number of products failed
		for ( let i = 0; i < 1; i++ ) { // @todo use 300
			const url = process.env.BASE_URL;
			try {
				const resp = await fetch( url );
				console.log( url, '--> ', resp.status );
			} catch ( error ) {
				console.error( 'ERROR! Failed to fetch base URL', resp.status );
			}
			await waitASecond();
			response = await restApi.get( `wps/v1/shop` );
			let total = 0;
			let status = parseInt( response.status );
			if ( status === 200 ) {
				if (
					typeof response.data !== 'undefined' &&
					typeof response.data.products !== 'undefined' &&
					typeof response.data.products.total !== 'undefined'
				) {
					total = parseInt( response.data.products.total );
					if ( total !== lastTotal ) {
						lastTotal = total;
					} else {
						same++;
					}
				}
				if ( total >= 18 ) {
					console.log( 'Stopping. Total number of products is as expected.');
					break;
				}
				if ( total !== 0 && same >= maxSame ) {
					console.log( 'Stopping. Total number of products is invariant.' );
					break;
				}
			} else {
				fails++;
				console.error( 'ERROR! Shop request failed', fails, response.status );
			}
			if ( fails >= maxFails ) {
				break;
			}
			console.log( '[' + i + '] ' + total + ' products' );
		}
	} catch ( error ) {
		console.error(
			'ERROR! Failed to poll product total:',
			error.data?.message || error
		);
	}
} );

exports.expect = base.expect;
