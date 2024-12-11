public class CloneQuote implements Finalizer, Queueable {
    private Map<Id, Id> sourceIdByClonedId;

    public CloneQuote(Map<Id, Opportunity> clonedRecords) {
        Map<Id, Id> result = new Map<Id, Id>();

        for(Opportunity curClonedRecord : clonedRecords.values()){
            result.put(curClonedRecord.Id, curClonedRecord.getCloneSourceId());
        }

        this.sourceIdByClonedId = result;
    }

    public void execute(QueueableContext context) {
        List<SBQQ__Quote__c> clonedList = new List<SBQQ__Quote__c>();

        Map<Id, List<SBQQ__Quote__c>> existingMap = new Map<Id, List<SBQQ__Quote__c>>([SELECT Id, (SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__r) FROM Opportunity WHERE Id IN : sourceIdByClonedId.values()]);

        for(Id cloneId : sourceIdByClonedId.keySet()){
            Id sourceId = sourceIdByClonedId.get(cloneId);

            if(existingMap.containsKey(sourceId)){
                for(SBQQ__Quote__c childRecord : existingMap.get(sourceId)){
                    SBQQ__Quote__c clonedChildRecord = childRecord.clone(false, true, false, false);
                    clonedChildRecord.SBQQ__Opportunity2__c = cloneId;
                    clonedList.add(clonedChildRecord);
                }
            }
        }

        if(clonedList.size() > 0){
            insert clonedList;

            // Call (Chained Queueable)
            ID jobID = System.enqueueJob(new CloneQuoteLines(new Map<Id, SBQQ__Quote__c>(clonedList)));
            System.debug('Quote Lines queueable job [' + jobID + '] enqueued successfully.');
        }
    }

    public void execute(FinalizerContext context) {
        String parentJobId = context.getAsyncApexJobId();

        if (context.getResult() == ParentJobResult.SUCCESS) {
            System.debug('Quote queueable job [' + parentJobId + '] completed successfully.');
        }

        //After all child quote line jobs finish, then recalculate the parent quote
        for(Id quoteId : sourceIdByClonedId.keySet()){
            SBQQ.QuoteAPI.QuoteCalculator quoteCalculator = new SBQQ.QuoteAPI.QuoteCalculator();
            quoteCalculator.loadQuote(quoteId);
            quoteCalculator.calculate();
        }
    }
}