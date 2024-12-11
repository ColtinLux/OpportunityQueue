public class CloneOpportunity implements Finalizer, Queueable {
    private Map<Id, Opportunity> opportunityMap;

    public CloneOpportunity(Map<Id, Opportunity> deliveryOpps) {
        this.opportunityMap = deliveryOpps;
    }

    public void execute(QueueableContext context) {
        List<Opportunity> clonedOpportunityList = new List<Opportunity>();

        for(Id curRecordId : opportunityMap.keySet()){
            Opportunity curOpportunity = opportunityMap.get(curRecordId);
            
            //Assumptions
            //Param 1 - PreserveId - No
            //Param 2 - isDeepClone - Yes
            //Param 3 - preserveReadonlyTimestamps - No
            //Param 4 - preserveAutonumber - No
            Opportunity clonedOpportunity = curOpportunity.clone(false, true, false, false);

            clonedOpportunityList.add(clonedOpportunity);
        }

        if(clonedOpportunityList.size() > 0){
            insert clonedOpportunityList;

            // Call (Chained Queueable)
            ID jobID = System.enqueueJob(new CloneQuote(new Map<Id, Opportunity>(clonedOpportunityList)));
        }
    }

    public void execute(FinalizerContext context) {
        String parentJobId = context.getAsyncApexJobId();

        if (context.getResult() == ParentJobResult.SUCCESS) {
            System.debug('Opportunity queueable job [' + parentJobId + '] completed successfully.');
        }
    }
}