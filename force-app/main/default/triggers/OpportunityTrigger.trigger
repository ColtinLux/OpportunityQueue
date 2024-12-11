/**
* @name: OpportunityTrigger
* @Description: This trigger is designed to respond to after insert, after update, and after undelete events on the Opportunity object.
*               It calls the OpportunityTriggerHelper class to perform specific logic when these events occur.
*/
trigger OpportunityTrigger on Opportunity (after insert, after update, after undelete) {
        Map<Id, Opportunity> newMap = Trigger.newMap;
        Map<Id, Opportunity> oldMap = Trigger.isUpdate ? Trigger.oldMap : null;

        OpportunityTriggerHelper.deliveryStageUpdate(newMap, oldMap);
}