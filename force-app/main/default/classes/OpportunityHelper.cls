/**
 * @description       :
 * @author            : admillican08@gmail.com
 * @group             :
 * @last modified on  : 07-07-2024
 * @last modified by  : admillican08@gmail.com
 **/

public with sharing class OpportunityHelper {
  // method called on Before Insert trigger that sets
  // the default Type for new Opportunities
  public void setDefaultOppType(List<Opportunity> oppLst) {
    for (Opportunity opp : oppLst) {
      if (opp.Type == null) {
        opp.Type = 'New Customer';
      }
    }
  }

  // method called on After Insert trigger that inserts
  // a Task for newly inserted Oppportunities
  public void insertTaskForNewOpps(Map<Id, Opportunity> oppMap) {
    System.debug('**Inserting task for new opportunity');
    List<Task> taskLst = new List<Task>();
    for (Opportunity opp : oppMap.values()) {
      Task tsk = new Task(
        Subject = 'Call Primary Contact',
        WhatId = opp.Id,
        WhoId = opp.Primary_Contact__c,
        OwnerId = opp.OwnerId,
        ActivityDate = Date.today().addDays(3)
      );
      taskLst.add(tsk);
    }
    insert as user taskLst;
  }

  // method called on Before Update trigger that sets the
  // Primary Contact on the Opportunity to the Contact
  //

  // method called on Before Update trigger that appends
  // stages to the Opportunity description
  public void updateDescWithStage(
    Map<Id, Opportunity> oppMap,
    Map<Id, Opportunity> oppMap2
  ) {
    for (Id sobjId : oppMap.keySet()) {
      Opportunity oldOpp = oppMap.get(sobjId);
      Opportunity newOpp = oppMap2.get(sobjId);
      System.debug('***oldOpp Stagename: ' + oldOpp.StageName);
      System.debug('***newOpp Stagename: ' + newOpp.StageName);
      if (
        !String.isBlank(oldOpp.Description) &&
        newOpp.StageName != oldOpp.StageName &&
        newOpp.StageName != null
      ) {
        newOpp.Description +=
          '\n Stage Change:' +
          newOpp.StageName +
          ':' +
          DateTime.now().format();
      } else if (
        String.isBlank(oldOpp.Description) &&
        newOpp.StageName != oldOpp.StageName &&
        newOpp.StageName != null
      ) {
        newOpp.Description =
          'Stage Change:' +
          newOpp.StageName +
          ':' +
          DateTime.now().format();
      }
    }
  }
  // method called on Before Update trigger that prevents
  // the saving of an Opportunity with an amount less than
  // or equal to $5000

  public void preventAmountLessThanFiveThousand(Map<Id, Opportunity> oppMap) {
    for (Opportunity opp : oppMap.values()) {
      if (opp.Amount <= 5000.00) {
        opp.addError('Opportunity amount must be greater than 5000');
      }
    }
  }

  // method called on Before Update trigger that sets the
  // Opportunity's Primary Contact to the CEO

  public void setPrimaryContactToCeo(Map<Id, Opportunity> oppMap) {
    //Get contacts related to the opportunity account

    Set<Id> accountIds = new Set<Id>();
    for (Opportunity opp : oppMap.values()) {
      accountIds.add(opp.AccountId);
    }

    Map<Id, Contact> contacts = new Map<Id, Contact>(
      [
        SELECT Id, FirstName, AccountId
        FROM Contact
        WHERE AccountId IN :accountIds AND Title = 'CEO'
        WITH USER_MODE
        ORDER BY FirstName ASC
      ]
    );
    Map<Id, Id> accountIdToContactId = new Map<Id, Id>();

    for (Contact cont : contacts.values()) {
      if (!accountIdToContactId.containsKey(cont.AccountId)) {
        accountIdToContactId.put(cont.AccountId, cont.Id);
      }
    }

    for (Opportunity opp : oppMap.values()) {
      if (
        opp.Primary_Contact__c == null &&
        accountIdToContactId.containsKey(opp.AccountId)
      ) {
        opp.Primary_Contact__c = accountIdToContactId.get(opp.AccountId);
      }
    }
  }

  // method called on Before Delete trigger that prevents
  // deletion of "Closed Won" Opportunities
  public void preventDeletionClosedOppsParentAcctBanking(
    Map<Id, Opportunity> oppMap
  ) {
    Map<Id, Account> acctMapIndustryBanking = new Map<Id, Account>(
      [
        SELECT Id, Industry
        FROM Account
        WHERE
          Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :oppMap.keySet())
          AND Industry = 'Banking'
        WITH USER_MODE
      ]
    );
    for (Opportunity opp : oppMap.values()) {
      if (
        opp.IsClosed &&
        opp.StageName.equals('Closed Won') &&
        acctMapIndustryBanking.keySet().contains(opp.AccountId)
      ) {
        opp.addError(
          'Cannot delete a closed won opportunity for a banking account'
        );
      }
    }
  }

  // method called on Before Delete trigger that prevents
  // deletion of closed Opportunities
  public void preventDeletionClosedOpps(Map<Id, Opportunity> oppMap) {
    for (Opportunity opp : oppMap.values()) {
      if (opp.IsClosed) {
        opp.addError('Cannot delete closed opportunity');
      }
    }
  }

  // method called on After Delete trigger to send an email to Opportunity owners
  // letting them know that their Opportunity was deleted
  public void notifyOwnersOpportunityDeleted(Map<Id, Opportunity> oppMap) {
    Set<Id> userIds = new Set<Id>();
    Map<Id, List<Opportunity>> userIdToOppLstMap = new Map<Id, List<Opportunity>>();
    for (Opportunity opp : oppMap.values()) {
      userIds.add(opp.OwnerId);
      if (!userIdToOppLstMap.keySet().contains(opp.OwnerId)) {
        List<Opportunity> oppLst = new List<Opportunity>();
        oppLst.add(opp);
        userIdToOppLstMap.put(opp.OwnerId, oppLst);
      } else {
        List<Opportunity> oppLst = userIdToOppLstMap.get(opp.OwnerId);
        oppLst.add(opp);
        userIdToOppLstMap.put(opp.OwnerId, oppLst);
      }
    }
    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    Map<Id, User> userIdToUserMap = new Map<Id, User>(
      [SELECT Id, Email FROM User WHERE Id = :userIds]
    );
    for (Id userId : userIdToUserMap.keySet()) {
      User usr = userIdToUserMap.get(userId);
      String emailAddr = usr.Email;
      List<String> emailLst = new List<String>{ emailAddr };
      if (userIdToOppLstMap.keySet().contains(userId)) {
        List<Opportunity> oppLst = userIdToOppLstMap.get(userId);
        for (Opportunity opp : oppLst) {
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          mail.setToAddresses(emailLst);
          mail.setSubject('Opportunity Deleted : ' + opp.Name);
          mail.setPlainTextBody(
            'Your Opportunity: ' + opp.Name + ' has been deleted.'
          );
          mails.add(mail);
        }
      }
    }
    try {
      Messaging.sendEmail(mails);
    } catch (Exception e) {
      System.debug('Exception: ' + e.getMessage());
    }
  }

  // method called on After Undelete trigger to assign a primary contact to
  // an Opportunity
  public void setPrimaryContactToSalesVp(Map<Id, Opportunity> oppMap) {
    Set<Id> accountIdSet = new Set<Id>();
    List<Opportunity> oppToUpdLst = new List<Opportunity>();
    Map<Id, Id> oppIdToAcctIdMap = new Map<Id, Id>();

    for (Opportunity opp : oppMap.values()) {
      accountIdSet.add(opp.AccountId);
      oppIdToAcctIdMap.put(opp.Id, opp.AccountId);
    }
    List<Contact> primaryContactLst = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Title = 'VP Sales' AND AccountId IN :accountIdSet
      WITH USER_MODE
    ];
    for (Opportunity opp : oppMap.values()) {
      Id acctId = oppIdToAcctIdMap.get(opp.Id);
      for (Contact con : primaryContactLst) {
        if (con.AccountId.equals(acctId) && opp.Primary_Contact__c == null) {
          Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
          oppToUpdate.Primary_Contact__c = con.Id;
          oppToUpdLst.add(oppToUpdate);
          break;
        }
      }
    }

    update as user oppToUpdLst;
  }
}
