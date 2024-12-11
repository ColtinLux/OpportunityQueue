/**
* @Name: OpportunityTrigger
* @Description: This trigger is designed to respond to after insert, after update, and after undelete events on the Opportunity object.
*               It calls the OpportunityTriggerHelper class to perform specific logic when these events occur.
*/
trigger OpportunityTrigger on Opportunity (after insert, after update, after undelete) {

        if(Trigger.isAfter){
                if(Trigger.isInsert){
                        OpportunityTriggerHelper.afterInsert(Trigger.newMap);
                } else if(Trigger.isUpdate){
                        OpportunityTriggerHelper.afterUpdate(Trigger.newMap, Trigger.oldMap);
                } else if(Trigger.isUndelete){
                        OpportunityTriggerHelper.afterUndelete(Trigger.newMap);
                }
        } else {
                //---------------------------------------------------------
                // Unused Contexts
                //---------------------------------------------------------
                //OpportunityTriggerHelper.beforeInsert();
                //OpportunityTriggerHelper.beforeUpdate();
                //OpportunityTriggerHelper.beforeDelete();
        }
}