//
//  MGWUIAPHelper.m
//  InAppRage
//
//  Created by Ray Wenderlich on 2/28/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "MGWUIAPHelper.h"

@implementation MGWUIAPHelper
@synthesize productIdentifiers = _productIdentifiers;
@synthesize products = _products;
@synthesize purchasedProducts = _purchasedProducts;
@synthesize request = _request;
@synthesize delegate;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        NSMutableSet * purchasedProducts = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [purchasedProducts addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            }
            NSLog(@"Not purchased: %@", productIdentifier);
        }
        self.purchasedProducts = purchasedProducts;
                        
    }
    return self;
}

- (void)requestProducts {
    
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _request.delegate = self;
    [_request start];
    
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSLog(@"Received products results...");   
    self.products = response.products;
    self.request = nil;     
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {    
    // TODO: Record the transaction on the server side...    
}

- (void)provideContent:(NSString *)productIdentifier {
    
    NSLog(@"Toggling flag for: %@", productIdentifier);
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_purchasedProducts addObject:productIdentifier];
    
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
   // NSLog(@"completeTransaction...");
    
    //[self recordTransaction: transaction];
    //[self provideContent: transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
	
	NSString *productID = transaction.payment.productIdentifier;
	[delegate purchased:productID];
    
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    //NSLog(@"restoreTransaction...");
    
    //[self recordTransaction: transaction];
    //[self provideContent: transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
//    if (transaction.error.code != SKErrorPaymentCancelled)
//    {
//        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
//    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    [delegate failedToPurchase:transaction.error.description];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)buyProductIdentifier:(NSString *)productIdentifier {
    
   // NSLog(@"Buying %@...", productIdentifier);
    
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

- (void)restore
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSMutableArray* purchasedItemIDs = [[NSMutableArray alloc] init];
//    NSLog(@"received restored transactions: %i", queue.transactions.count);
	
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        NSString *productID = transaction.payment.productIdentifier;
        [purchasedItemIDs addObject:productID];
//        NSLog("%@",purchasedItemIDs);
    }
	
	[delegate restored:purchasedItemIDs];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	[delegate failedToRestore:error.description];
}

@end
