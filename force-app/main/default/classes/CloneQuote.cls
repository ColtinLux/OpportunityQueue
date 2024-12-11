public class CloneQuote implements Finalizer, Queueable {
    private Map<Id, Opportunity> opportunityMap;
    private Map<Id, Id> sourceOpportunityIdByClonedOpportunityId;

    public CloneQuote(Map<Id, Opportunity> clonedOpps) {
        Map<Id, Id> oppIdByClonedOppId = new Map<Id, Id>();

        for(Opportunity clonedOpportunity : clonedOpps.values()){
            oppIdByClonedOppId.put(clonedOpportunity.Id, clonedOpportunity.getCloneSourceId());
        }

        this.sourceOpportunityIdByClonedOpportunityId = oppIdByClonedOppId;
        this.opportunityMap = clonedOpps;
    }

    public void execute(QueueableContext context) {
        List<SBQQ__Quote__c> clonedQuoteList = new List<SBQQ__Quote__c>();

        Map<Id, List<SBQQ__Quote__c>> existingQuoteMap = new Map<Id, List<SBQQ__Quote__c>>([SELECT Id, (SELECT Id FROM SBQQ__Quote__r) FROM Opportunity WHERE Id IN : sourceOpportunityIdByClonedOpportunityId.values()]);

        for(Id cloneRecordId : sourceOpportunityIdByClonedOpportunityId.keySet()){
            Opportunity curOpportunity = opportunityMap.get(cloneRecordId);
            Id sourceOpportunityId = sourceOpportunityIdByClonedOpportunityId.get(cloneRecordId);

            for(SBQQ__Quote__c quote : existingQuoteMap.get(sourceOpportunityId)){
                SBQQ__Quote__c clonedQuote = quote.clone(false, true, false, false);
                clonedQuote.SBQQ__Opportunity2__c = cloneRecordId;
                clonedQuoteList.add(quote);
            }
        }

        if(clonedQuoteList.size() > 0){
            insert clonedQuoteList;

            // Call (Chained Queueable)
            //ID jobID = System.enqueueJob(new CloneQuoteLines(new Map<Id, SBQQ__Quote__c>(clonedQuoteList)));
        }
    }

    public void execute(FinalizerContext context) {
        String parentJobId = context.getAsyncApexJobId();

        if (context.getResult() == ParentJobResult.SUCCESS) {
            System.debug('Opportunity queueable job [' + parentJobId + '] completed successfully.');
        }
    }
}