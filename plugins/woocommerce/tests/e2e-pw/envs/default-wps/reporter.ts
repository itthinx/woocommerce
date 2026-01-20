/**
 * External dependencies
 */
import type {
	FullConfig,
	FullResult,
	Reporter,
	Suite,
	TestCase,
	TestResult
} from '@playwright/test/reporter';

import { createClient, WP_API_PATH } from '@woocommerce/e2e-utils-playwright';
import { admin } from '../../test-data/data';
import playwrightConfig from '../../playwright.config';

const api = createClient( playwrightConfig.use.baseURL, {
	type: 'basic',
	username: admin.username,
	password: admin.password,
} );

type AutoUseFixtures = {
	myAutoFixture: void;
};

class IndexerReporter implements Reporter {

	waiting = false;

	onBegin( config: FullConfig, suite: Suite ) {
		console.log(
			`Starting the run with ${ suite.allTests().length } tests`
		);

		// console.log( 'SUITE TESTS = ', suite.allTests() );

		suite.allTests().forEach( ( test ) => {
			// console.log( 'SUITE / TEST / TYPE = ', test._testType.test );
			// console.log( ' XXXXXXXXXX test.id = ', test.id ); // @todo remove
			// test._testType.test.beforeEach( async ( { page }, testInfo ) => {
			// 	// Extend timeout for all tests running this hook by 30 seconds.
			// 	testInfo.setTimeout( testInfo.timeout + 30000 );
			// } );
			test._testType.test.extend< AutoUseFixtures >( {
				// beforeEach: async ( { page } ) => {
				// 	console.log( ' YYYYYYYYYY' );
				// 	await this.waitForIndexer( test )
				// },
				myAutoFixture: [
					async ( {}, use, testInfo ) => {
						// before the test
						console.log(
							`----- WPS ----- [MyAutoFixture] Starting test: ${ testInfo.title }`
						);
						// run the test
						await use();
						// after the test
						console.log(
							`----- WPS ----- [MyAutoFixture] Finishing test: ${ testInfo.title }`
						);
					},
					{ auto: true }, // this is an automatic fixture
				],
			} );
			// console.log( ' XXXXXXXXXX ...test = ', test._testType.test ); // @todo remove
		} );
	}

	async onTestBegin( test: TestCase, result: TestResult ) {
		console.log( `Starting test ${ test.title } waiting for indexer ...` );
		// console.log( 'TESTS : ', test.parent.tests.pop()._testType );
//		console.log( 'TYPE ', test._testType );

//		test._testType.test.beforeEach( () => {
//			console.log( 'WPS BEFOREEACH' );
//		} );

//		test._testType.test.extend(
//			beforeEach: async ( { page }, use ) => {
//				console.log( 'WPS INSIDE' );
//			}
//		);

		// this gets it called but it's not "waiting"
		test._testType.test.extend( {
			waitForIndexer: await this.waitForIndexer( test ),

			beforeEach: async ( { page } ) => {
				console.log( 'XXXXXXXXXX' );
			},
		} );

		// waitForIndexer is async but we really need to wait until it's done its job
		// and because there's no way to do a blocking execution of an async function,
		// we use a flag and our pseudoSleep
		// and of course this doesn't work because Javascript sucks
		// and hangs on the main thread, so the code inside waitForIndexer
		// stops being executed as soon as it gets to the first await ...
		//
//		this.waiting = true;
//		this.waitForIndexer( test );
//		while ( this.waiting ) {
//			process.stdout.write( '.' );
//			this.pseudoSleep( 1 );
//		}

		// this doesn't work either, it simply shifts the problem around
//		( async function ( self ) {
//			await self.waitForIndexer( test );
//		} )( this );

		// it seems the only way to get this done is to avoid any asynchronous functions
		// this means, rewrite waitForIndexer so it is not async
		// and does not use any await inside

//		this.waiting = true;
		// ( async () => await this.waitForIndexer( test ) )();

//		await this.waitForIndexer( test );

//		while ( this.waiting ) {
//			( async ( self ) =>
//				await new Promise( ( resolve ) => {
//					console.log( 'resolve before' );
//					process.stdout.write( '.' );
//					console.log( 'resolve after' );
//					setTimeout( resolve, 1000 );
//				} ) )( this );
//		}

		console.log( `... indexer ready, starting test ${ test.title }` );
	}

	onTestEnd( test: TestCase, result: TestResult ) {
		console.log( `Finished test ${ test.title }: ${ result.status }` );
	}

	onEnd( result: FullResult ) {
		console.log( `Finished the run: ${ result.status }` );
	}

	pseudoSleep( seconds ) {
		const ms = seconds * 1000;
		const start = new Date().getTime();
		let now;
		do {
			Math.sqrt( Math.random() * Number.MAX_SAFE_INTEGER );
			now = new Date().getTime();
		} while ( now - start < ms );
	}

	waitASecond() {
		return new Promise( resolve => setTimeout( resolve, 1000 ) );
	}

	waitForIndexer = async ( test: TestCase ) => {
		try {
			console.log( 'WPS INDEX REPORTER WAIT FOR INDEXER' );

			// @todo increase timeout for the test while this goes on

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
			// https://woocommerce.github.io/woocommerce-rest-api-docs/#list-all-products
			const products = await api.get( `wc/v3/products`, {
				params: {
					_fields: [ 'id' ],
					per_page: 1,
				},
			} );
console.log( 'A' );
			let totalProducts = 0;
			if ( products.status === 200 ) {
				if ( typeof products.headers !== 'undefined' ) {
					if (
						typeof products.headers[ 'x-wp-total' ] !== 'undefined'
					) {
						totalProducts = products.headers[ 'x-wp-total' ];
					}
				}
			}
console.log( 'B' );
			console.log( 'totalProducts : ', totalProducts ); // @todo remove
			if ( totalProducts === 0 ) {
				return;
			}

			const maxFails = 10;
			const maxSame = 30;
			let fails = 0;
			let lastTotal = null;
			let same = 0;
			// wait up to 5 minutes OR
			// until the number of products stays invariant for 30 seconds OR
			// 10 attempts to obtain the number of products failed
			for ( let i = 0; i < 300; i++ ) {
				const url = process.env.BASE_URL;
				try {
					const resp = await fetch( url );
					console.log( url, '--> ', resp.status );
				} catch ( error ) {
					console.error( 'ERROR! Failed to fetch base URL', resp.status );
				}
				await this.waitASecond();
				const response = await api.get( `wps/v1/shop` );
				let total = 0;
				if ( response.status === 200 ) {
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
					if ( total >= totalProducts ) {
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
		} finally {
			this.waiting = false;
		}
	};
}

console.log( 'WPS REPORTER' ); // @todo remove

export default IndexerReporter;
