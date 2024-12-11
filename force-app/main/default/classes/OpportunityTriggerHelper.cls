/**
* @Name: OpportunityTriggerHelper
* @Description: Business logic to be applied to Opportunities via the OpportunityTrigger.
*/
public with sharing class OpportunityTriggerHelper {

    //---------------------------------------------------------
    // Trigger Contexts
    //---------------------------------------------------------

    public static void beforeInsert(){}
    public static void beforeUpdate(){}
    public static void beforeDelete(){}

    public static void afterInsert(Map<Id, Opportunity> newMap){
        deliveryStageUpdate(newMap, null);
    }

    public static void afterUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){
        deliveryStageUpdate(newMap, oldMap);
    }

    public static void afterUndelete(Map<Id, Opportunity> newMap){
        deliveryStageUpdate(newMap, null);
    }

    //---------------------------------------------------------
    // Custom Logic
    //---------------------------------------------------------

    /**
     * Business Logic
     * When an Opportunity's Stage field is set to Delivery
     * Clone the Opportunity, its Quote & Quote Lines, then Recalculate the Quote
     * Jira: 1234
     */
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