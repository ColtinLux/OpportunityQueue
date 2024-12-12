/**
* @Name: CloneRecordsQueue
* @Description: Clone Records
*/
public class CloneRecordsQueue implements Finalizer, Queueable {
    private Map<Id, SObject> recordsToProcessMap;
    private Map<Id, Id> recordIdToSourceIdMap;
    private Boolean relatedRecordEval;

    public CloneRecordsQueue(Map<Id, SObject> recordsToProcess, Boolean relatedRecordEvaluation) {

        Map<Id, Id> tempMap = new Map<Id, Id>();
        for(SObject currentRecord : recordsToProcessMap.values()){

            /**
             * if the object doesn't need record reparenting, the getCloneSourceId() method returns null
             * if the object needs record reparenting, the getCloneSourceId() method returns the original/source recordId
             */

            Id sourceId = (currentRecord.getCloneSourceId() != null && relatedRecordEvaluation) ? currentRecord.getCloneSourceId() : currentRecord.Id;
            tempMap.put(currentRecord.Id, sourceId);
        }

        this.recordsToProcessMap = recordsToProcess;
        this.recordIdToSourceIdMap = tempMap;
        this.relatedRecordEval = relatedRecordEvaluation;
    }

    //-------------------------------------------------
    // Queueable Execution
    //-------------------------------------------------
    public void execute(QueueableContext context) {
        List<SObject> clonedList = new List<SObject>();

        Map<Id, List<SObject>> combinedChildMap = relatedRecordEval ? queryChildRecords(recordIdToSourceIdMap) : new Map<Id, List<SObject>>();

        for(Id recordId : recordIdToSourceIdMap.keySet()){
            Id sourceId = recordIdToSourceIdMap.get(recordId);

            if(!relatedRecordEval && recordsToProcessMap.containsKey(recordId)){
                SObject recordToClone = recordsToProcessMap.get(recordId);
                clonedList.add(getClone(recordToClone));
            } else if(relatedRecordEval && combinedChildMap.containsKey(sourceId)){

                for(SObject childRecord : combinedChildMap.get(sourceId)){
                    SObject clonedChildRecord = getClone(childRecord);
                    String relationshipFieldToReparent = getParentField(childRecord);

                    if(relationshipFieldToReparent.isNotEmpty()){
                        clonedChildRecord.put(relationshipFieldToReparent, recordId);
                    }

                    clonedList.add(clonedChildRecord);
                }
            }
        }

        if(clonedList.size() > 0){
            insert clonedList;

            Boolean childRecordsToProcess = false;

            if(clonedList[0].getSObjectType().getDescribe().getName().contains('Opportunity')){
                childRecordsToProcess = true;
            } else if(clonedList[0].getSObjectType().getDescribe().getName().contains('SBQQ__Quote__c')){
                childRecordsToProcess = true;
            }

            if(childRecordsToProcess){
                // Call (Chained Queueable)
                ID jobID = System.enqueueJob(new CloneRecordsQueue(new Map<Id, SObject>(clonedList), true));
                System.debug('Queueable job [' + jobID + '] enqueued successfully.');
            }
        }
    }

    public Map<Id, List<SObject>> queryChildRecords(Map<Id, Id> recIdMap) {
        Map<Id, List<SObject>> childRecordMap = new Map<Id, List<SObject>>();

        Map<Id, List<SBQQ__Quote__c>> existingQuotesMap = new Map<Id, List<SBQQ__Quote__c>>(
            [SELECT Id, (SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__r) 
            FROM Opportunity WHERE Id IN : recIdMap.values()]
        );

        Map<Id, List<SBQQ__QuoteLine__c>> existingQuoteLinesMap = new Map<Id, List<SBQQ__QuoteLine__c>>(
            [SELECT Id, (SELECT Id FROM SBQQ__QuoteLine__r) 
            FROM SBQQ__Quote__c WHERE Id IN : recIdMap.values()
        ]);

        combinedChildMap.putAll(existingQuotesMap);
        combinedChildMap.putAll(existingQuoteLinesMap);

        return childRecordMap;
    }

    public SObject getClone(SObject curRecord){
        //Assumptions
        //Param 1 - PreserveId - No
        //Param 2 - isDeepClone - Yes
        //Param 3 - preserveReadonlyTimestamps - No
        //Param 4 - preserveAutonumber - No
        SObject clonedRecord = curRecord.clone(false, true, false, false);

        return clonedRecord;
    }

    public String getParentField(SObject childRecord){
        //This mapping could be stored in metadata for easier maintenance

        String objectType = childRecord.getSObjectType().getDescribe().getName();

        if(objectType == 'SBQQ__Quote__c'){
            return 'SBQQ__Opportunity2__c';
        } else if(objectType == 'SBQQ__QuoteLine__c'){
            return 'SBQQ__Quote__c';
        } else {
            return null;
        }
    }

    //-------------------------------------------------
    // Queueable Execution Complete
    //-------------------------------------------------
    public void execute(FinalizerContext context) {
        String parentJobId = context.getAsyncApexJobId();

        if (context.getResult() == ParentJobResult.SUCCESS) {
            System.debug('SObject Clone queueable job [' + parentJobId + '] completed successfully.');
        }

        if(recordIdToSourceIdMap.isNotEmpty() && recordIdToSourceIdMap[0].getSObjectType().getDescribe().getName().contains('SBQQ__Quote__c')){
            for(Id quoteId : sourceIdByClonedId.keySet()){
                SBQQ.QuoteAPI.QuoteCalculator quoteCalculator = new SBQQ.QuoteAPI.QuoteCalculator();
                quoteCalculator.loadQuote(quoteId);
                quoteCalculator.calculate();
            }
        }
    }
}