# Opportunity Queue

Whenever an Opportunity is moved to the stage “Delivery” initiate a series of chained queueables that create a clone of the Opportunity, the CPQ Quote, and the CPQ Quotelines. The opportunity record should be created in the first queueable, the Quote and Quote lines should be created in their own subsequent queueables. Please include a finalizer for every queueable. 
Note: You cannot invoke a quote calculation from a queueable so the quote calculation must be invoked in the finalizer.

## Approach Number 1

### Trigger

1. OpportunityTrigger - determines the trigger contexts to run

2. OpportunityTriggerHelper - determines criteria for cloning process & executes CloneOpportunity

### Clone Queueables

3. CloneOpportunity - clones the opportunity & executes CloneQuote (passing the cloned opportunity records)

4. CloneQuote - clones the quotes related to the source opportunities, reparents them to the cloned opportunities & executes CloneQuoteLines (passing the cloned Quote records), on completion of the child quote line batches, the finalizer will recalculate their parent quote.

5. CloneQuoteLines - clones the quote lines related to the source quote, reparents them to the cloned quote

### CPQ Quote Calculator

6. QuoteCalculator - used to call the QuoteAPI calculate function

7. SaveCalcution - used as a callback for when the calculation is complete, used to call the QuoteAPI save function


## Approach Number 2

### Trigger

1. OpportunityTrigger - determines the trigger contexts to run

2. OpportunityTriggerHelper - determines criteria for cloning process & executes CloneRecordsQueue by passing in the list of opportunities that meet the criteria outlined in the opportunity trigger and a false value for CloneRelatedRecords.

### Clone Recursive Queueable

3. CloneRecordsQueue - passed in opportunities, executes CloneRecordsQueue by passing in the list of cloned opportunities and a true value for CloneRelatedRecords

(Recursion) CloneRecordsQueue - passed in cloned opportunities, executes CloneRecordsQueue by passing in the list of cloned quotes and a true value for CloneRelatedRecords.

(Recursion) CloneRecordsQueue - passed in cloned quotes, finishes execution of logic resulting in a list of cloned quotelines, reparents them

### CPQ Quote Calculator

4. QuoteCalculator - used to call the QuoteAPI calculate function

5. SaveCalcution - used as a callback for when the calculation is complete, used to call the QuoteAPI save function