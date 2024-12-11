public class CloneQuoteLines implements Finalizer, Queueable {
    private Map<Id, Id> sourceIdByClonedId;

    public CloneQuoteLines(Map<Id, SBQQ__Quote__c> clonedRecs) {
        Map<Id, Id> result = new Map<Id, Id>();

        for(SBQQ__Quote__c clonedRecord : clonedRecs.values()){
            result.put(clonedRecord.Id, clonedRecord.getCloneSourceId());
        }

        this.sourceIdByClonedId = result;
    }

    public void execute(QueueableContext context) {
        List<SBQQ__Quote__c> clonedList = new List<SBQQ__Quote__c>();

        Map<Id, List<SBQQ__Quote__c>> existingQuoteLinesMap = new Map<Id, List<SBQQ__Quote__c>>([SELECT Id, (SELECT Id FROM SBQQ__QuoteLine__r) FROM SBQQ__Quote__c WHERE Id IN : sourceIdByClonedId.values()]);

        for(Id cloneRecordId : sourceIdByClonedId.keySet()){
            Id sourceId = sourceIdByClonedId.get(cloneRecordId);

            for(SBQQ__QuoteLine__c existingRecord : existingQuoteLinesMap.get(sourceId)){
                SBQQ__QuoteLine__c clonedQuoteLine = existingRecord.clone(false, true, false, false);
                clonedQuoteLine.SBQQ__Quote__c = cloneRecordId;
                clonedList.add(clonedQuoteLine);
            }
        }

        if(clonedList.size() > 0){
            insert clonedList;
        }
    }

    public void execute(FinalizerContext context) {
        String parentJobId = context.getAsyncApexJobId();

        if (context.getResult() == ParentJobResult.SUCCESS) {
            System.debug('Quote Lines queueable job [' + parentJobId + '] completed successfully.');
        }
    }
}