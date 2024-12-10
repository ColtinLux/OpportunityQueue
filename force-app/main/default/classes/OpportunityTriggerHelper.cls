public with sharing class OpportunityTriggerHelper {
    public static void deliveryStageUpdate(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){
        Map<Id, Opportunity> result = new Map<Id, Opportunity>();
        
        for(Id curRecordId : newMap.keySet()){
            Opportunity newOpp = newMap.get(curRecordId);

            if(!newOpp.isClone()){
                if(oldMap != null){
                    if((newOpp.StageName.contains('Delivery')) && (!oldMap.get(curRecordId).StageName.contains('Delivery'))){
                        result.put(curRecordId, newOpp);
                    }
                } else {
                    if(newOpp.StageName.contains('Delivery')){
                        result.put(curRecordId, newOpp);
                    }
                }
            }
        }
        
        if(result.keySet().size() > 0){
            ID jobID = System.enqueueJob(new CloneOpportunity(result));
        }
    }
}