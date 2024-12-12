/**
* @Name: CloneQuote
* @Description: Clone Quote, associate to Cloned Opportunity, Execute CloneQuoteLines
*/
public class CloneQuote implements Finalizer, Queueable {
    private Map<Id, Id> sourceIdByClonedId;  //clonedRecordId > sourceRecordId

    public CloneQuote(Map<Id, Opportunity> clonedRecords) {
        Map<Id, Id> result = new Map<Id, Id>();

        for(Opportunity curClonedRecord : clonedRecords.values()){
            result.put(curClonedRecord.Id, curClonedRecord.getCloneSourceId());
        }

        this.sourceIdByClonedId = result;
    }

    //-------------------------------------------------
    // Queueable Execution
    //-------------------------------------------------
    public void execute(QueueableContext context) {
        List<SBQQ__Quote__c> clonedList = new List<SBQQ__Quote__c>();

        Map<Id, List<SBQQ__Quote__c>> existingMap = new Map<Id, List<SBQQ__Quote__c>>(
            [SELECT Id, (SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__r) 
            FROM Opportunity WHERE Id IN : sourceIdByClonedId.values()]
        );

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

    //-------------------------------------------------
    // Queueable Execution Complete
    //-------------------------------------------------
    public void execute(FinalizerContext context) {
        String parentJobId = context.getAsyncApexJobId();

        if (context.getResult() == ParentJobResult.SUCCESS) {
            System.debug('Quote queueable job [' + parentJobId + '] completed successfully.');
        }

        if(sourceIdByClonedId != null && sourceIdByClonedId.values().size() > 0 && sourceIdByClonedId.values()[0].getSObjectType().getDescribe().getName().contains('SBQQ__Quote__c')){
            for(Id quoteId : sourceIdByClonedId.keySet()){
                SObject quoteRecord = recordsToProcessMap.get(quoteId);
                CloneQuote.QuoteModel quoteModel = new CloneQuote.QuoteModel(quoteRecord);
                QuoteCalculator quoteCalculator = new QuoteCalculator();
                quoteCalculator.calculate(quoteModel, 'SaveCalculation');
            }
        }
    }

    public class QuoteModel {
        public SObject record;
        public Integer nextKey;
        public Boolean applyAdditionalDiscountLast;
        public Boolean applyPartnerDiscountFirst;
        public Boolean channelDiscountsOffList;
        public Decimal customerTotal;
        public Decimal netTotal;
        public Decimal netNonSegmentTotal;

        public QuoteModel(SObject record){
            this.record = record;
            this.nextKey = 1;
            this.applyAdditionalDiscountLast = false;
            this.applyPartnerDiscountFirst = false;
            this.channelDiscountsOffList = false;
        }
    }
}