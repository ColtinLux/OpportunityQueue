# Opportunity Queue

Whenever an Opportunity is moved to the stage “Delivery” initiate a series of chained queueables that create a clone of the Opportunity, the CPQ Quote, and the CPQ Quotelines. The opportunity record should be created in the first queueable, the Quote and Quote lines should be created in their own subsequent queueables. Please include a finalizer for every queueable. 
Note: You cannot invoke a quote calculation from a queueable so the quote calculation must be invoked in the finalizer.

## Approach Number 1

### Trigger

1. OpportunityTrigger - determines the trigger contexts to run

2. OpportunityTriggerHelper - determines criteria for cloning process & executes CloneOpportunity

### Clone Queueables

3. CloneOpportunity - clones the list of opportunities & executes CloneQuote (passing the cloned opportunity records)

4. CloneQuote - clones the list of quotes related to the source opportunities (derived from the passed in opportunities), reparents them to the cloned opportunities & executes CloneQuoteLines (passing the cloned quote records), on completion of the child quote line batches, the finalizer will recalculate their parent quote

5. CloneQuoteLines - clones the quote lines related to the source quote (derived from the passed in quotes), reparents them to the cloned quotes and finishes execution

### CPQ Quote Calculator

6. QuoteCalculator - used to call the QuoteAPI calculate function

7. SaveCalcution - used as a callback for when the calculation is complete, used to call the QuoteAPI save function


## Approach Number 2

### Trigger

1. OpportunityTrigger - determines the trigger contexts to run

2. OpportunityTriggerHelper - determines criteria for cloning process & executes CloneRecordsQueue (passing in the list of evaluated opportunities) and a false value for CloneRelatedRecords

### Clone Recursive Queueable

3. CloneRecordsQueue - passed in list of opportunities to clone, clones the list of opportunities (can dismiss or not dismiss previously cloned opps), then executes CloneRecordsQueue by passing in the list of cloned opportunities and a true value for CloneRelatedRecords

(Recursion) CloneRecordsQueue - passed in list of cloned opportunities, finds the clone's sourceId, finds the child records related to the sourceId (in this case, quotes related to the previously cloned opportunity), clones the child records and reparents them to the cloned record, then executes CloneRecordsQueue by passing in the list of cloned quotes and a true value for CloneRelatedRecords

(Recursion) CloneRecordsQueue - passed in list of cloned quotes, finds the clone's sourceId, finds the child records related to the sourceId (in this case, quotes lines related to the previously cloned quote), clones the child records and reparents them to the cloned record, then finishes execution of logic resulting in a list of cloned quote lines

### CPQ Quote Calculator

4. QuoteCalculator - used to call the QuoteAPI calculate function

5. SaveCalcution - used as a callback for when the calculation is complete, used to call the QuoteAPI save function