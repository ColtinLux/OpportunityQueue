trigger OpportunityTrigger on Opportunity (after insert, after update, after undelete) {
        if(Trigger.isInsert || Trigger.isUndelete){
                OpportunityTriggerHelper.deliveryStageUpdate(Trigger.newMap, null);
        } else {
                OpportunityTriggerHelper.deliveryStageUpdate(Trigger.newMap, Trigger.oldMap);
        }
}