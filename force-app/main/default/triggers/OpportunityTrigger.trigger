/**
 * @description       :
 * @author            : admillican08@gmail.com
 * @group             :
 * @last modified on  : 07-05-2024
 * @last modified by  : admillican08@gmail.com
 **/
trigger OpportunityTrigger on Opportunity(
  before insert,
  after insert,
  before update,
  before delete,
  after delete,
  after undelete
) {
  if (Trigger.isInsert) {
    if (Trigger.isBefore) {
      OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler(
        Trigger.new
      );
      oppHandler.run();
    } else if (Trigger.isAfter) {
      OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler(
        Trigger.newMap
      );
      oppHandler.run();
    }
  } else if (Trigger.isUpdate) {
    if (Trigger.isBefore) {
      OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler(
        Trigger.oldMap,
        Trigger.newMap
      );
      oppHandler.run();
    }
  } else if (Trigger.isDelete) {
    if (Trigger.isBefore) {
      OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler(
        Trigger.oldMap
      );
      oppHandler.run();
    } else if (Trigger.isAfter) {
      OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler(
        Trigger.oldMap
      );
      oppHandler.run();
    }
  } else if (Trigger.isUndelete) {
    if (Trigger.isAfter) {
      OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler(
        Trigger.newMap
      );
      oppHandler.run();
    }
  }
}
