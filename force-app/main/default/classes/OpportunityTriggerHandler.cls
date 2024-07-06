/**
 * @description       :
 * @author            : admillican08@gmail.com
 * @group             :
 * @last modified on  : 07-05-2024
 * @last modified by  : admillican08@gmail.com
 **/

public with sharing class OpportunityTriggerHandler extends TriggerHandler {
  public OpportunityHelper oppHelper;
  public List<Opportunity> oppLst = new List<Opportunity>();
  public Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
  public Map<Id, Opportunity> oppMap2 = new Map<Id, Opportunity>();

  public OpportunityTriggerHandler(List<sObject> recordsLst) {
    super();
    this.oppHelper = new OpportunityHelper();
    this.oppLst = convertTriggerListToAccts(recordsLst);
  }

  public OpportunityTriggerHandler(Map<Id, sObject> recordsMap) {
    // recordsMap can stand for Trigger.newMap or Trigger.oldMap
    super();
    this.oppHelper = new OpportunityHelper();
    this.oppMap = convertTriggerMapToAccts(recordsMap);
  }

  public OpportunityTriggerHandler(
    // recordsMap = Trigger.oldMap
    // recordsMap2 = Trigger.newMap
    Map<Id, sObject> recordsMap, //old
    Map<Id, sObject> recordsMap2
  ) {
    //new
    super();
    this.oppHelper = new OpportunityHelper();
    this.oppMap = convertTriggerMapToAccts(recordsMap);
    this.oppMap2 = convertTriggerMapToAccts(recordsMap2);
  }

  public static List<Opportunity> convertTriggerListToAccts(
    List<sObject> objLst
  ) {
    List<Opportunity> oppLst = new List<Opportunity>();
    for (sObject obj : objLst) {
      oppLst.add((Opportunity) obj);
    }
    return oppLst;
  }

  public static Map<Id, Opportunity> convertTriggerMapToAccts(
    Map<Id, sObject> objMap
  ) {
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    for (Id objId : objMap.keySet()) {
      sObject obj = objMap.get(objId);
      oppMap.put(objId, (Opportunity) obj);
    }
    return oppMap;
  }

  public override void beforeInsert() {
    oppHelper.setDefaultOppType(this.oppLst);
  }

  public override void afterInsert() {
    oppHelper.insertTaskForNewOpps(this.oppMap);
  }

  public override void beforeUpdate() {
    oppHelper.preventAmountLessThanFiveThousand(this.oppMap2);
    oppHelper.setPrimaryContactToCeo(this.oppMap2);
    oppHelper.updateDescWithStage(this.oppMap, this.oppMap2);
  }

  public override void beforeDelete() {
    oppHelper.preventDeletionClosedOppsParentAcctBanking(this.oppMap);
    oppHelper.preventDeletionClosedOpps(this.oppMap);
  }

  public override void afterDelete() {
    oppHelper.notifyOwnersOpportunityDeleted(this.oppMap);
  }

  public override void afterUndelete() {
    oppHelper.setPrimaryContactToSalesVp(this.oppMap);
  }
}
