/**
 * @description       :
 * @author            : admillican08@gmail.com
 * @group             :
 * @last modified on  : 07-05-2024
 * @last modified by  : admillican08@gmail.com
 **/

public with sharing class AccountTriggerHandler extends TriggerHandler {
  public AccountHelper acctHelper;
  public List<Account> acctLst = new List<Account>();
  public Map<Id, Account> acctMap = new Map<Id, Account>();

  public AccountTriggerHandler(List<sObject> recordsLst) {
    super();
    this.acctHelper = new AccountHelper();
    this.acctLst = convertTriggerListToAccts(recordsLst);
  }

  public AccountTriggerHandler(Map<Id, sObject> recordsMap) {
    super();
    this.acctHelper = new AccountHelper();
    this.acctMap = convertTriggerMapToAccts(recordsMap);
  }

  public static List<Account> convertTriggerListToAccts(List<sObject> objLst) {
    List<Account> acctLst = new List<Account>();
    for (sObject obj : objLst) {
      acctLst.add((Account) obj);
    }
    return acctLst;
  }

  public static Map<Id, Account> convertTriggerMapToAccts(
    Map<Id, sObject> objMap
  ) {
    Map<Id, Account> acctMap = new Map<Id, Account>();
    for (Id objId : objMap.keySet()) {
      sObject obj = objMap.get(objId);
      acctMap.put(objId, (Account) obj);
    }
    return acctMap;
  }

  public override void beforeInsert() {
    acctHelper.setTypeProspect(this.acctLst);
    acctHelper.copyAddress(this.acctLst);
    acctHelper.setRating(this.acctLst);
  }

  public override void afterInsert() {
    acctHelper.setDefaultContact(this.acctMap);
  }
}
