public class CloneOpportunity implements Finalizer, Queueable {
    private Map<Id, Opportunity> existingMap;

    public CloneOpportunity(Map<Id, Opportunity> deliveryOpps) {
        this.existingMap = deliveryOpps;
    }

    public void execute(QueueableContext context) {
        List<Opportunity> clonedList = new List<Opportunity>();

        for(Id curRecordId : existingMap.keySet()){
            Opportunity curRecord = existingMap.get(curRecordId);
            
            //Assumptions
            //Param 1 - PreserveId - No
            //Param 2 - isDeepClone - Yes
            //Param 3 - preserveReadonlyTimestamps - No
            //Param 4 - preserveAutonumber - No
            Opportunity clonedRecord = curRecord.clone(false, true, false, false);

            clonedList.add(clonedRecord);
        }

        if(clonedList.size() > 0){
            insert clonedList;

            // Call (Chained Queueable)
            ID jobID = System.enqueueJob(new CloneQuote(new Map<Id, Opportunity>(clonedList)));
        }
    }

    public void execute(FinalizerContext context) {
        String parentJobId = context.getAsyncApexJobId();

        if (context.getResult() == ParentJobResult.SUCCESS) {
            System.debug('Opportunity queueable job [' + parentJobId + '] completed successfully.');
        }
    }
}