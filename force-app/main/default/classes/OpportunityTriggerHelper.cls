public with sharing class OpportunityTriggerHelper {
    public static void deliveryStageUpdate(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){
        Map<Id, Opportunity> result = new Map<Id, Opportunity>();
        
        for(Id curRecordId : newMap.keySet()){
            if(oldMap != null){
                if((newMap.get(curRecordId).StageName.contains('Delivery')) && (!oldMap.get(curRecordId).StageName.contains('Delivery'))){
                    result.put(curRecordId, newMap.get(curRecordId));
                }
            } else {
                if(newMap.get(curRecordId).StageName.contains('Delivery')){
                    result.put(curRecordId, newMap.get(curRecordId));
                }
            }
        }
        
        if(result.keySet().size() > 0){
            //ID jobID = System.enqueueJob(new CloneOpportunity(result));
        }
    }
}